module EGS
  module Models
    class FreeGame < Sequel::Model
      many_to_one :release

      def eql?(other)
        title == other.title &&
          start_date == other.start_date &&
          end_date == other.end_date
      end

      def hash
        title.hash ^
          start_date.hash ^
          end_date.hash
      end

      def <=>(other)
        end_date <=> other.end_date
      end

      alias == eql?
    end

    class Release < Sequel::Model
      one_to_many :free_games

      def self.last
        super || new
      end

      def time_left
        end_date.nil? ? 0 : (end_date - Time.now).ceil
      end
    end
  end
end
