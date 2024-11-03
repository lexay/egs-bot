module EGS
  module Models
    class Game < Sequel::Model
      plugin :validation_helpers

      def validate
        super
        validates_presence %i[title start_date end_date price]
        validates_unique %i[title start_date end_date]
        errors.add(:price, 'cannot be more than 0') if price.positive?
      end
    end
  end
end
