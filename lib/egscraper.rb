class GameHash < Hash
  include Hashie::Extensions::DeepFind
end
class GameArray < Array
  include Hashie::Extensions::DeepFind
end

module EGS
  class Promotion
    PROMO = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=RU&allowCountries=RU'.freeze
    GQL = 'https://www.epicgames.com/graphql'.freeze
    GAME_INFO_RU = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze
    GAME_INFO = 'https://store-content.ak.epicgames.com/api/en-US/content/products/'.freeze
    PRODUCT = 'https://www.epicgames.com/store/ru/product/'.freeze

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

        def post(uri_string, **options)
          uri = URI.parse(uri_string)
          request = Net::HTTP::Post.new(uri)

          request['Accept'] = 'application/json, text/plain, */*'
          request['Content-Type'] ||= options[:content]
          request.body ||= options[:body]

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
          parse(promotions)
        end

        private

        def fetch_all_promotions
          games = Request.get(PROMO, content: 'application/json;charset=utf-8')
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

        def parse(games_and_addons)
          ids = fetch_ids(games_and_addons)
          uris = fetch_uris(ids)
          games_only = fetch_games_only(ids)
          bootstrap(games_and_addons, games_only, uris)
        end

        def bootstrap(games_and_addons, games_only, uris)
          bootstraped = []

          count = games_and_addons.count

          0.upto(count - 1) do |idx|
            current_game = games_and_addons[idx]

            game_attributes = 
              { start_date: fetch_date(current_game, 'startDate'),
                end_date: fetch_date(current_game, 'endDate'),
                pubs_n_devs: fetch_pubs_n_devs(current_game) }

            current_game = games_only[idx]

            game_attributes.merge!(
              { title: fetch_title(current_game),
                short_description: fetch_description(current_game, 'shortDescription'),
                full_description: fetch_description(current_game, 'description'),
                game_uri: uris[idx],
                timestamp: Time.now }
            )
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

        def fetch_date(game, date)
          Time.parse GameHash[game].deep_find(date)
        end

        def fetch_ids(games)
          games.map do |game|
            game['productSlug'].chomp('/home')[/[-[:alnum:]]+/] # %r{^[^\/]}
          end
        end

        def fetch_pubs_n_devs(game)
          devs = game['customAttributes'].select do |attribute|
            attribute['key'] == 'developerName' ||
              attribute['key'] == 'publisherName'
          end
          devs.map { |dev_or_pub| dev_or_pub['value'] }.join(' / ')
        end

        def fetch_games_only(ids)
          games_only = []
          ids.each do |id|
            game_or_addon = Request.get(GAME_INFO_RU + id)
            game_or_addon['pages'].each do |page|
              games_only.push(page) if page['type'] == 'productHome'
              sleep rand(0.75..1.5)
            end
          end
          games_only
        end

        def fetch_description(game, description)
          desc = GameHash[game].deep_find(description) || '-'
          sanitize(desc)
        end

        def sanitize(description)
          description.delete! '*'
          description.delete! '#'
          pattern = /!?\[.+\)/
          description.partition(pattern).delete_if { |str| str =~ pattern }.join.strip
        end

        def fetch_title(game)
          GameHash[game].deep_find('navTitle').strip
        end

        def fetch_uris(ids)
          ids.map { |id| PRODUCT + id }
        end
      end
    end
  end
end
