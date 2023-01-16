module ScraperHelper
  include Hashie::Extensions::DeepFind

  def api?
    !self[:product_slug].nil?
  end

  def current_and_free?
    current_promo = self.dig(:promotions, :promotional_offers)
    return false if current_promo.nil? || current_promo.empty?

    self.deep_find(:discount_price).to_f.zero?
  end
end
