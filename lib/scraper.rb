module EGS
  class Scraper
    BASE_URI = "https://store.epicgames.com/#{I18n.t(:locale)}/p/".freeze

    class << self
      def run
        data = fetch_games_data
        data.deep_transform_keys! { |k| k.underscore.to_sym }
        parse_games(data)
      end

      private

      def fetch_games_data
        uri = format(ENV['PROMO'], I18n.t(:locale), I18n.t(:country), I18n.t(:country))
        response = Request.get(uri)
        if response.is_a? Net::HTTPOK
          JSON.parse(response.body)
        else
          LOG.error(I18n.t(:response, code: response.code, message: response.message, uri: response.uri))
          exit
        end
      end

      def parse_games(data)
        games = data.dig(:data, :catalog, :search_store, :elements)
        games.map do |g|
          {
            title: parse_title(g),
            start_date: parse_start_date(g),
            end_date: parse_end_date(g),
            price: parse_price(g),
            uri: parse_uri(g)
          }
        end
      end

      def parse_title(game)
        game[:title]
      end

      def parse_start_date(game)
        parse_date(game, :start_date)
      end

      def parse_end_date(game)
        parse_date(game, :end_date)
      end

      def parse_date(game, date)
        current_promo_date = game.dig(
          :promotions,
          :promotional_offers, 0,
          :promotional_offers, 0,
          date
        )
        current_promo_date.nil? ? nil : Time.parse(current_promo_date)
      end

      def parse_slug(game)
        slug = game[:product_slug] || game.dig(:offer_mappings, 0, :page_slug)
        slug.slice(/[A-z0-9-]+/)
      end

      def parse_uri(game)
        slug = parse_slug(game)
        BASE_URI + slug
      end

      def parse_price(game)
        game.dig(:price, :total_price, :discount_price)
      end
    end
  end
end
