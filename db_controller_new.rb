require 'sequel'
require 'pry'
require_relative 'db_model'
require_relative 'user_model'

module DB
  MYDB = Sequel.connect('sqlite://test.db')
  class << self
    def insert(item)
      case item
      when FreeGame
        MYDB[:free_games].insert(
          title: item.title,
          short_description: item.short_description,
          full_description: item.full_description,
          pubs_n_devs: item.pubs_n_devs,
          game_uri: item.game_uri,
          start_date: item.start_date,
          end_date: item.end_date,
          timestamp: item.timestamp
        )
      when User
        MYDB[:users].insert(
          name: item.name,
          chat_id: item.chat_id,
          timestamp: item.timestamp
        )
      end
    end

    def table_empty?(table)
      MYDB[table].empty?
    end

    def table_exists?(table)
      MYDB.table_exists?(table)
    end

    def create(table)
      MYDB.create_table table do
        case table
        when 'free_games'
          primary_key :id
          String :title
          String :full_description
          String :short_description
          String :pubs_n_devs
          String :game_uri
          String :start_date
          String :end_date
          String :timestamp
        when 'users'
          primary_key :id
          String :name
          Integer :chat_id
          String :timestamp
        end
      end
    end

    def clear(table)
      MYDB.drop_table(table.to_sym)
    end

    def games(count = 1)
      begin
        games = MYDB[:free_games].order(:id).last(count)
      rescue Sequel::Error
        return []
      end
      games.map! { |game| FreeGame.new(game) }
    end

    def users
      MYDB[:users]
    end

    def chat_ids
      users.map(:chat_id)
    end

    def unsubscribe(chat_id)
      users.where(chat_id: chat_id).delete
    end

  end
end

# p DB.table_empty? 'users'
# p DB.table_exists? 'users'
# p DB.user_chat_ids
# p DB.users.find_user(:name, 'lexxorg')
