module EGS
  class Scraper
    PROMO = "https://store-site-backend-static-ipv4.ak.epicgames.com/freeGamesPromotions?locale=#{I18n.t(:locale)}&country=#{I18n.t(:country)}&allowCountries=#{I18n.t(:country)}".freeze
    class << self
      def run
        fetch_free_games
      end

      private

      def fetch_free_games
        promoted = fetch_promoted_games
        parse_free_games(promoted)
      end

      def parse_free_games(promoted)
        promoted
          .select(&:current_and_free)
          .map { |p| Models::FreeGame.new(**p.to_h) }
      end

      def fetch_promoted_games
        response = Request.get(PROMO)
        if response.is_a? Net::HTTPOK
          JSON
            .parse(response.body)
            .deep_transform_keys { |key| key.underscore.to_sym }
            .dig(:data, :catalog, :search_store, :elements)
            .map { |d| Promotion.new(d) }
        else
          LOG.info(I18n.t(:response, code: response.code, message: response.message, uri: response.uri))
          exit
        end
      end
    end
  end
end
