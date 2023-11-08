module EGS
  class Promotion
    BASE_URI = "https://store.epicgames.com/#{I18n.t(:locale)}/p/".freeze

    attr_reader :title, :start_date, :end_date, :slug, :uri, :description, :discount_price, :current_and_free

    def initialize(data)
      @title = parse_title(data)
      @start_date = parse_start_date(data)
      @end_date = parse_end_date(data)
      @discount_price = parse_discount_price(data)
      @slug = parse_slug(data)
      @uri = parse_uri
      @description = parse_description(data)
      @current_and_free = current_and_free?
    end

    def to_h
      { title:, start_date:, end_date:, uri:, description: }
    end

    private

    def parse_title(data)
      data.dig(:title)
    end

    def parse_start_date(data)
      parse_date(data, :start_date)
    end

    def parse_end_date(data)
      parse_date(data, :end_date)
    end

    def parse_date(data, date)
      current_promo_date = data.dig(
        :promotions,
        :promotional_offers, 0,
        :promotional_offers, 0,
        date
      )
      current_promo_date.nil? ? nil : Time.parse(current_promo_date)
    end

    def parse_slug(data)
      slug = data.dig(:product_slug) || data.dig(:offer_mappings, 0, :page_slug)
      slug.slice(/[A-z0-9-]+/)
    end

    def parse_uri
      BASE_URI + slug
    end

    def parse_description(data)
      description = data.dig(:short_description) || data.dig(:description)
      description
        .strip
        .delete('*#_')
        .split("\n\n")
        .reject { |sentence| sentence.slice(/!?\[.+\)/) }
        .join("\n\n")
        .capitalize
    end

    def parse_discount_price(data)
      data.dig(:price, :total_price, :discount_price)
    end

    def free?
      discount_price.to_f.zero?
    end

    def current?
      !!(start_date && end_date)
    end

    def current_and_free?
      current? && free?
    end
  end
end
