class GameHash < Hash
  include Hashie::Extensions::DeepFind
end
class GameArray < Array
  include Hashie::Extensions::DeepFind
end

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

          response.code == '200' ? JSON.parse(response.body) : []
        end
      end
    end

    class Parser
      class << self
        def run
          promotions = fetch_free_n_current
          bootstrap(promotions)
        end

        private

        def fetch_all_promotions
          games = Request.get(PROMO_RU, content: 'application/json;charset=utf-8')
          GameHash[games].deep_find('elements') unless games.empty?
        end

        def fetch_free_n_current
          all_promotions = fetch_all_promotions
          all_promotions.select do |promotion|
            offered_game = promotion.dig('promotions', 'promotionalOffers')
            next unless current?(offered_game)
            next unless free?(offered_game)

            promotion
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
                start_date: fetch_date(game_or_addon, 'startDate'),
                end_date: fetch_date(game_or_addon, 'endDate'),
                release_id: EGS::Models::Release.last.id }
            bootstraped.push(EGS::Models::FreeGame.new(game_attributes))
          end
          bootstraped
        end

        def current?(game)
          game.nil? || game.empty? ? false : true
        end

        def free?(game)
          GameArray.new(game).deep_find('discountPercentage').zero?
        end

        def fetch_title(game)
          title = game['title']
          title.empty? ? fallback(game, 'navTitle') : title
        end

        def fetch_description(game)
          short_desc = game['description']
          true_desc = short_desc.length < 20 || not_ru_lang?(short_desc) ? fallback(game, 'description') : short_desc
          sanitize(true_desc)
        end

        def not_ru_lang?(description)
          description[/[А-я]+/].nil?
        end

        def sanitize(description)
          description.delete! '*'
          description.delete! '#'
          description.delete! '_'
          description.strip!
          pattern = /!?\[.+\)/
          description.split("\n\n").reject { |sentence| sentence[pattern] }.join
        end

        def fallback(game, attribute)
          id = fetch_id(game)
          request = Request.get(GAME_INFO_RU + id)
          base_game = request['pages'].select { |page| page['type'] == 'productHome' }
          GameArray.new(base_game).deep_find(attribute)
        end

        def fetch_pubs_n_devs(game)
          devs = game['customAttributes'].select do |attribute|
            attribute['key'] == 'developerName' ||
              attribute['key'] == 'publisherName'
          end
          devs.map { |dev_or_pub| dev_or_pub['value'] }.uniq.join(' / ')
        end

        def fetch_id(game)
          game['productSlug'].chomp('/home')[/[-[:alnum:]]+/] # %r{^[^\/]}
        end

        def fetch_uri(game)
          id = fetch_id(game)
          BASE_URI + id
        end

        def fetch_date(game, date)
          Time.parse GameHash[game].deep_find(date)
        end
      end
    end
  end
end
