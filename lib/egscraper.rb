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
          []
        end
      end
    end

    class Scraper
      class << self
        def run
          games = fetch_games
          bootstrap(games)
        end

        private

        def fetch_games
          request = Request.get(PROMO, content: 'application/json;charset=utf-8')
          all_promo_games = request.dig(:data, :catalog, :search_store, :elements)
          all_promo_games.select do |game|
            game.extend ScraperHelper
            game.current_and_free?
          end
        end

        def bootstrap(games_and_addons)
          bootstraped = []
          games_and_addons.each do |game_or_addon|
            game_attributes =
              { title: fetch_title(game_or_addon),
                description: fetch_description(game_or_addon),
                pubs_n_devs: fetch_pubs_n_devs(game_or_addon),
                game_uri: fetch_uri(game_or_addon),
                start_date: fetch_date(game_or_addon, :start_date),
                end_date: fetch_date(game_or_addon, :end_date) }
            bootstraped.push(EGS::Models::FreeGame.new(game_attributes))
          end
          bootstraped
        end

        def fetch_title(game)
          title = game[:title]
          return title if game.no_api?
          return title unless title.empty?

          fetch_api(game)[:nav_title]
        end

        def fetch_description(game)
          description = parse_description(game)
          sanitize(description)
        end

        def parse_description(game)
          return game[:description] if game.no_api?

          fetch_api(game)[:short_description]
        end

        def sanitize(description)
          description.delete! '*#_'
          description.strip!
          pattern = /!?\[.+\)/
          description.split("\n\n").reject { |sentence| sentence[pattern] }.join("\n\n")
        end

        def fetch_pubs_n_devs(game)
          return game.deep_find(:seller)[:name] if game.no_api?

          info = fetch_api(game)
          publisher = info[:publisher_attribution]
          developer = info[:developer_attribution]
          [publisher, developer].uniq.join(' - ')
        end

        def fetch_api(game)
          id = fetch_id(game)
          request = Request.get(API + id)
          base_game = request[:pages].select { |page| page[:type] == 'productHome' }
          base_game.extend Hashie::Extensions::DeepFind
          base_game.deep_find(:about)
        end

        def fetch_id(game)
          return game.deep_find(:page_slug) if game.no_api?

          id = game[:product_slug]
          id.chomp('/home')[/[-[:alnum:]]+/]
        end

        def fetch_uri(game)
          id = fetch_id(game)
          BASE_URI + id
        end

        def fetch_date(game, date)
          Time.parse game.deep_find(date)
        end
      end
    end
  end
end
