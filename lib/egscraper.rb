module EGS
  class Promotion
    locale = I18n.t(:locale)
    country = I18n.t(:country)
    PROMO = "https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=#{locale}&country=#{country}&allowCountries=#{country}".freeze
    API = "https://store-content.ak.epicgames.com/api/#{locale}/content/products/".freeze
    BASE_URI = "https://store.epicgames.com/#{locale}/p/".freeze

    class Request
      class << self
        def get(uri_string, **options)
          uri = URI.parse(uri_string)
          request = Net::HTTP::Get.new(uri)

          request['Accept'] = 'application/json, text/plain, */*'
          request['Content-Type'] ||= options[:content]

          secure = { use_ssl: uri.scheme == 'https' }

          response = Net::HTTP.start(uri.hostname, uri.port, secure) do |http|
            http.request(request)
          end

          case response
          when Net::HTTPOK
            hash = JSON.parse(response.body)
            hash.deep_transform_keys! { |key| key.underscore.to_sym }
          else
            exit
          end
        rescue SystemExit
          EGS::LOG.info "Response has returned #{response.code}. Exiting..."
          {}
        end
      end
    end

    class Scraper
      class << self
        def run
          games = fetch_games
          bootstrap(games) unless games.empty?
        end

        private

        def fetch_games
          response = Request.get(PROMO, content: 'application/json;charset=utf-8')
          return response if response.empty?

          all_promo_games = response.dig(:data, :catalog, :search_store, :elements)
          all_promo_games.select do |game|
            game.extend ScraperHelper
            game.current_and_free?
          end
        end

        def bootstrap(games_and_addons)
          bootstraped = []
          games_and_addons.each do |game_or_addon|
            attributes = fetch_attributes(game_or_addon)
            bootstraped.push(EGS::Models::FreeGame.new(attributes))
          end
          bootstraped
        end

        def fetch_attributes(game)
          api = fetch_api(game)
          attributes = %w[title start_date end_date uri description publisher developer]
          attributes.reduce(Hash.new) do |hash, atr|
            method = 'fetch_' + atr
            called = send(method, game)
            hash[atr.to_sym] = called.to_s.empty? && api ? send(method, api) : called
            hash
          end
        end

        def fetch_title(game)
          game[:title] || game[:nav_title]
        end

        def fetch_description(game)
          description = parse_description(game)
          sanitize(description)
        end

        def parse_description(game)
          game[:short_description] || game[:description]
        end

        def sanitize(description)
          pattern = /!?\[.+\)/
          description.strip
                     .delete('*#_')
                     .split("\n\n")
                     .reject { |sentence| sentence[pattern] }
                     .join("\n\n")
        end

        def fetch_publisher(game)
          game.dig(:seller, :name) || game[:publisher_attribution]
        end

        def fetch_developer(game)
          game[:developer_attribution]
        end

        def fetch_api(game)
          id = fetch_id(game)
          response = Request.get(API + id)
          return response if response.empty?

          base_game = response[:pages]
                      .select { |page| page[:type] == 'productHome' && page[:_title] =~ /home/i }
                      .shift
          base_game.dig(:data, :about)
        end

        def fetch_id(game)
          id = game[:product_slug]
          id&.slice(/[A-z0-9-]+/)
        end

        def fetch_uri(game)
          id = fetch_id(game)
          id = id.nil? ? game.deep_find(:page_slug) : id
          BASE_URI + id
        end

        def fetch_start_date(game)
          fetch_date(game, :start_date)
        end

        def fetch_end_date(game)
          fetch_date(game, :end_date)
        end

        def fetch_date(game, date)
          Time.parse game.deep_find(date)
        end
      end
    end
  end
end
