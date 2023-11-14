module EGS
  class Scraper
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
        promo = format(ENV['PROMO'], I18n.t(:locale), I18n.t(:country), I18n.t(:country))
        response = Request.get(promo)
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
