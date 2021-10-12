module EGS
  module Models
    class FreeGame < Sequel::Model
      many_to_one :release

      def self.games(count = 1)
        order_by(:id).last(count)
      end

      def self.next_date
        games.empty? ? nil : games.last.end_date
      end
    end

    class User < Sequel::Model
      def self.chat_ids
        all.map(&:chat_id)
      end

      def self.unsubscribe(chat_id)
        where(chat_id: chat_id).delete
      end
    end

    class Release < Sequel::Model
      one_to_many :free_games
    end
  end
end
