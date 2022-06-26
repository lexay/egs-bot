module ScraperHelper
  include Hashie::Extensions::DeepFind

  def no_api?
    self[:product_slug].nil?
  end

  def current_and_free?
    current_promo = self.dig(:promotions, :promotional_offers)
    return false if current_promo.nil? || current_promo.empty?

    self.deep_find(:discount_percentage).zero?
  end
end
