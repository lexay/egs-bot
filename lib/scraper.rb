module EGS
  class Scraper
    PROMO = "https://store-site-backend-static-ipv4.ak.epicgames.com/freeGamesPromotions?locale=#{I18n.t(:locale)}&country=#{I18n.t(:country)}&allowCountries=#{I18n.t(:country)}".freeze
    class << self
      def run
        fetch_games
      end

      private

      def fetch_games
        response = Request.get(PROMO, content: 'application/json;charset=utf-8')
        return response if response.empty?

        response
          .dig(:data, :catalog, :search_store, :elements)
          .map { |d| Promotion.new(d) }
          .select(&:current_and_free)
          .map { |p| Models::FreeGame.new(**p.to_h) }
      end
    end
  end
end
