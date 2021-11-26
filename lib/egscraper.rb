module EGS
  class Promotion
    PROMO_RU = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=ru&country=RU&allowCountries=RU'.freeze
    BASE_URI = 'https://www.epicgames.com/store/ru/product/'.freeze
    GAME_INFO_RU = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze

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
            current_and_free?(game)
          end
        end

        def current_and_free?(game)
          game_type = game.dig(:promotions, :promotional_offers)
          return false if game_type.nil? || game_type.empty?

          game.extend Hashie::Extensions::DeepFind
          game.deep_find(:discount_percentage).zero?
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
                end_date: fetch_date(game_or_addon, :end_date),
                release_id: EGS::Models::Release.last.id }
            bootstraped.push(EGS::Models::FreeGame.new(game_attributes))
          end
          bootstraped
        end

        def fetch_title(game)
          title = game[:title]
          title.empty? ? fetch_about(game)[:nav_title] : title
        end

        def fetch_description(game)
          short_desc = game[:description]
          true_desc = short_desc.length < 50 || not_ru_lang?(short_desc) ? fetch_about(game)[:description] : short_desc
          sanitize(true_desc)
        end

        def not_ru_lang?(description)
          description[/[А-я]+/].nil?
        end

        def sanitize(description)
          description.delete! '*#_'
          description.strip!
          pattern = /!?\[.+\)/
          description.split("\n\n").reject { |sentence| sentence[pattern] }.join("\n\n")
        end

        def fetch_about(game)
          id = fetch_id(game)
          request = Request.get(GAME_INFO_RU + id)
          base_game = request[:pages].select { |page| page[:type] == 'productHome' }
          base_game.extend Hashie::Extensions::DeepFind
          base_game.deep_find(:about)
        end

        def fetch_pubs_n_devs(game)
          publisher = nil
          developer = nil
          attributes = game[:custom_attributes]
          attributes.each do |attribute|
            developer = attribute[:value] if attribute[:key] == 'developerName'
            publisher = attribute[:value] if attribute[:key] == 'publisherName'
          end
          about_section = fetch_about(game) if publisher.nil? || developer.nil?
          publisher ||= about_section[:publisher_attribution]
          developer ||= about_section[:developer_attribution]
          [developer, publisher].uniq.join(' - ')
        end

        def fetch_id(game)
          game[:product_slug].chomp('/home')[/[-[:alnum:]]+/] # %r{^[^\/]}
        end

        def fetch_uri(game)
          id = fetch_id(game)
          BASE_URI + id
        end

        def fetch_date(game, date)
          game.extend Hashie::Extensions::DeepFind
          Time.parse game.deep_find(date)
        end
      end
    end
  end
end
