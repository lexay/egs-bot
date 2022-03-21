module ScraperHelper
  include Hashie::Extensions::DeepFind

  def a_pack?
    self[:product_slug].nil?
  end

  def current_and_free?
    game_type = self.dig(:promotions, :promotional_offers)
    return false if game_type.nil? || game_type.empty?

    self.deep_find(:discount_percentage).zero?
  end
end
