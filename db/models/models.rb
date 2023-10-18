module EGS
  module Models
    class FreeGame < Sequel::Model
      many_to_one :release

      def eql?(other)
        self.title == other.title && self.start_date == other.start_date
      end

      def hash
        self.title.hash ^ self.start_date.hash
      end

      def <=>(other)
        self.end_date <=> other.end_date
      end

      alias == eql?
    end

    class Release < Sequel::Model
      one_to_many :free_games

      def self.last
        super || self.new
      end

      def time_left
        self.end_date.nil? ? 0 : (self.end_date - Time.now).ceil
      end
    end
  end
end
