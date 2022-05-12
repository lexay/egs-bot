module EGS
  class Promotion
    PROMO_RU = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=ru&country=RU&allowCountries=RU'.freeze
    BASE_URI = 'https://store.epicgames.com/ru/p/'.freeze
    API_INFO_RU = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze

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

          (EGS::LOG.info "Response has returned #{response.code}. Exiting..."; exit) unless response.code == '200'

          hash = JSON.parse(response.body)
          hash.deep_transform_keys! { |key| key.underscore.to_sym }
        end
      end
    end

    class Parser
      class << self
        def run
          games = fetch_games
          bootstrap(games)
        end

        private

        def fetch_games
          request = Request.get(PROMO_RU, content: 'application/json;charset=utf-8')
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
          return title if game.has_no_api_info?
          return title unless title.empty?

          fetch_api(game)[:nav_title]
        end

        def fetch_description(game)
          description = parse_description(game)
          sanitize(description)
        end

        def parse_description(game)
          description = game[:description]
          return description if game.has_no_api_info?
          return description if !(description.nil? || description.empty?) &&
                                ru_lang?(description) &&
                                description.length > 50

          fetch_api(game)[:description]
        end

        def ru_lang?(description)
          !description[/[А-я]+/].nil?
        end

        def sanitize(description)
          description.delete! '*#_'
          description.strip!
          pattern = /!?\[.+\)/
          description.split("\n\n").reject { |sentence| sentence[pattern] }.join("\n\n")
        end

        def fetch_api(game)
          id = fetch_id(game)
          request = Request.get(API_INFO_RU + id)
          base_game = request[:pages].select { |page| page[:type] == 'productHome' }
          base_game.extend Hashie::Extensions::DeepFind
          base_game.deep_find(:about)
        end

        def fetch_pubs_n_devs(game)
          return game.deep_find(:seller)[:name] if game.has_no_api_info?

          api_info = fetch_api(game) if publisher.nil? || developer.nil?
          publisher = api_info[:publisher_attribution]
          developer = api_info[:developer_attribution]
          [publisher, developer].uniq.join(' - ')
        end

        def fetch_id(game)
          return game.deep_find(:page_slug) if game.has_no_api_info?

          game_slug = game[:product_slug]
          game_slug.chomp('/home')[/[-[:alnum:]]+/] # %r{^[^\/]}
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
