module ScraperHelper
  include Hashie::Extensions::DeepFind

  def has_no_api_info?
    self[:product_slug].nil?
  end

  def current_and_free?
    game_type = self.dig(:promotions, :promotional_offers)
    return false if game_type.nil? || game_type.empty?

    self.deep_find(:discount_percentage).zero?
  end
end
