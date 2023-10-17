module EGS
  class Promotion
    PROMO = "https://store-site-backend-static-ipv4.ak.epicgames.com/freeGamesPromotions?locale=#{I18n.t(:locale)}&country=#{I18n.t(:country)}&allowCountries=#{I18n.t(:country)}".freeze
    API = "https://store-content.ak.epicgames.com/api/#{I18n.t(:locale)}/content/products/".freeze
    GQL = 'https://store.epicgames.com/graphql'.freeze
    GQL_CATALOG = "[{\"query\":\"query catalogQuery($productNamespace: String!, $offerId: String!, $locale: String) {\\n Catalog {\\n catalogOffer(namespace: $productNamespace, id: $offerId, locale: $locale) {\\n title\\n description\\n developerDisplayName\\n publisherDisplayName\\n}\\n}\\n }\\n\",\"variables\":{\"productNamespace\":\"%s\",\"offerId\":\"%s\",\"locale\":\"%s\"}}]".freeze
    BASE_URI = "https://store.epicgames.com/#{I18n.t(:locale)}/p/".freeze

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

          promoted_games = response.dig(:data, :catalog, :search_store, :elements)
          promoted_games.select do |game|
            game.extend ScraperHelper
            game.current_and_free?
          end
        end

        def bootstrap(games_and_addons)
          games_and_addons.map do |game_or_addon|
            attributes = fetch_attributes(game_or_addon)
            Models::FreeGame.new(attributes)
          end
        end

        def fetch_attributes(game)
          attributes = %w[title start_date end_date uri description publisher developer]
          backend = fetch_backend(game)
          attributes.inject(Hash.new) do |hash, atr|
            method = 'fetch_' + atr
            k = atr.to_sym
            v = attributes.last(3).include?(atr) ? send(method, backend) : send(method, game)
            hash.store(k, v)
            hash
          end
        end

        def fetch_backend(game)
          api = fetch_api(game)
          api.empty? ? fetch_gql(game) : api
        end

        def fetch_api(game)
          slug = fetch_slug(game)
          version = slug.slice(/--.+/)
          base_slug = slug.chomp(version)
          response = Request.get(API + base_slug)
          return response if response.empty?

          response
            .dig(:pages)
            .select { |p| p.dig(:type) == 'productHome' && p.dig(:_title) =~ /home/i }
            .shift
            .dig(:data, :about)
        end

        def fetch_slug(game)
          slug = game.dig(:product_slug) || game.deep_find(:page_slug)
          slug&.slice(/[A-z0-9-]+/)
        end

        def fetch_gql(game)
          id = game.dig(:id)
          namespace = game.dig(:namespace)
          locale = I18n.t(:locale)
          response = Request.post(GQL, id:, namespace:, locale:)
          return response if response.empty?

          response.dig(:data, :catalog, :catalog_offer)
        end

        def fetch_title(game)
          game.dig(:title)
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
          slug = fetch_slug(game)
          BASE_URI + slug
        end

        def fetch_description(game)
          description = game.dig(:short_description) || game.dig(:description)
          sanitize(description)
        end

        def sanitize(description)
          pattern = /!?\[.+\)/
          description
            &.strip
            .delete('*#_')
            .split("\n\n")
            .reject { |sentence| sentence.slice(pattern) }
            .join("\n\n")
        end

        def fetch_publisher(game)
          game.dig(:publisher_attribution) || game.dig(:publisher_display_name)
        end

        def fetch_developer(game)
          game.dig(:developer_attribution) || game.dig(:developer_display_name)
        end
      end
    end
  end
end
