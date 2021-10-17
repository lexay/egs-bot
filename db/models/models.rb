module EGS
  module Models
    class FreeGame < Sequel::Model
      many_to_one :release

      def self.next_date
        last.end_date
      end
    end

    class User < Sequel::Model
      plugin :validation_helpers
      self.raise_on_save_failure = false

      def validate
        super
        validates_unique :chat_id
      end

      def self.chat_ids
        all.map(&:chat_id)
      end

      def self.subscribe(username, chat_id)
        User.new(name: username, chat_id: chat_id).save
      end

      def self.unsubscribe(chat_id)
        where(chat_id: chat_id).delete
      end
    end

    class Release < Sequel::Model
      one_to_many :free_games
      def self.init
        Release.create(chat_ids_not_served: JSON.pretty_generate(EGS::Models::User.chat_ids))
      end
    end
  end
end
