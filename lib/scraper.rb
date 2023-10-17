module EGS
  class Promotion
    BASE_URI = "https://store.epicgames.com/#{I18n.t(:locale)}/p/".freeze
    API = "https://store-content.ak.epicgames.com/api/#{I18n.t(:locale)}/content/products/".freeze
    PROMO = "https://store-site-backend-static-ipv4.ak.epicgames.com/freeGamesPromotions?locale=#{I18n.t(:locale)}&country=#{I18n.t(:country)}&allowCountries=#{I18n.t(:country)}".freeze
    GQL = 'https://store.epicgames.com/graphql'.freeze
    GQL_CATALOG = "[{\"query\":\"query catalogQuery($productNamespace: String!, $offerId: String!, $locale: String) {\\n Catalog {\\n catalogOffer(namespace: $productNamespace, id: $offerId, locale: $locale) {\\n title\\n description\\n developerDisplayName\\n publisherDisplayName\\n}\\n}\\n }\\n\",\"variables\":{\"productNamespace\":\"%s\",\"offerId\":\"%s\",\"locale\":\"%s\"}}]".freeze

    class Scraper
      class << self
        def run
          games = fetch_games
          bootstrap(games)
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
            bootstraped.push(Models::FreeGame.new(attributes))
          end
          bootstraped
        end

        def fetch_attributes(game)
          attributes = %w[title start_date end_date uri description publisher developer]
          backend = fetch_backend(game)
          attributes.reduce(Hash.new) do |hash, atr|
            method = 'fetch_' + atr
            hash[atr.to_sym] = attributes.last(3).include?(atr) ? send(method, backend) : send(method, game)
            hash
          end
        end

        def fetch_backend(game)
          api = fetch_api(game)
          api.empty? ? fetch_gql_catalog(game) : api
        end

        def fetch_api(game)
          id = fetch_id(game)
          version = id.slice(/--.+/)
          base_id = id.chomp(version)
          response = Request.get(API + base_id)
          return response if response.empty?

          base_game = response[:pages]
                      .select { |page| page[:type] == 'productHome' && page[:_title] =~ /home/i }
                      .shift
          base_game.dig(:data, :about)
        end

        def fetch_id(game)
          id = game[:product_slug] || game.deep_find(:page_slug)
          id&.slice(/[A-z0-9-]+/)
        end

        def fetch_gql_catalog(game)
          variables = { variables: [I18n.t(:locale), I18n.t(:country), game[:id], game.deep_find(:namespace)] }
          response = RequestGQL.get(CATALOG, **variables) 
          response.dig(:data, :catalog, :catalog_offer)
        end

        def fetch_title(game)
          game[:title]
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

        def fetch_uri(game)
          id = fetch_id(game)
          BASE_URI + id
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
          game[:publisher_attribution] || game[:publisher_display_name]
        end

        def fetch_developer(game)
          game[:developer_attribution] || game[:developer_display_name]
        end
      end
    end
  end
end
