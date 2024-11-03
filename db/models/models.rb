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
      end
    end
  end
end
