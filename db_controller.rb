require 'sqlite3'
require 'pry'
require_relative 'db_model'
require_relative 'user_model'

module DB
  class << self
    def db(default = { results_as_hash: true })
      SQLite3::Database.new('./test.db', default)
    end

    def insert(item)
      case item
      when FreeGame
        db.execute("insert into free_games (title, short_description, full_description,
                    pubs_n_devs, game_uri, start_date, end_date, timestamp)
                    values (?, ?, ?, ?, ?, ?, ?, ?)",
                    item.title, item.short_description, item.full_description,
                    item.pubs_n_devs, item.game_uri, item.start_date,
                    item.end_date, item.timestamp)
      when User
        db.execute("insert into users (name, chat_id, timestamp)
                   values (?, ?, ?)", item.name, item.chat_id, item.timestamp)
      end
    end

    def table_empty?(table)
      request = db(results_as_hash: false).execute("select count(*) from #{table}")
      request.dig(0, 0).zero?
    end

    def table_exists?(table)
      request = db(results_as_hash: false).execute("select name from sqlite_master where type='table'")
      request.flatten.any? { |e| e == table }
      # binding.pry
    end

    def create(table)
      case table
      when 'free_games'
        table_new = <<~SQL
          create table free_games (
            id integer primary key,
            title string,
            full_description text,
            short_description text,
            pubs_n_devs string,
            game_uri string,
            start_date string,
            end_date string,
            timestamp string);
        SQL
      when 'users'
        table_new = 'create table users (id integer primary key, name string,
        chat_id string, timestamp string)'
      end
      db.execute(table_new)
    end

    def clear(table)
      db.execute("drop table #{table};")
    end

    def get
      games = db.execute('select * from free_games;')
      games.map! { |game| game.transform_keys(&:to_sym) }
      games.map! { |game| FreeGame.new(game) }
    end

    def user_chat_ids
      db(results_as_hash: false).execute('select chat_id from users;').flatten.uniq 
    end

    def unsubscribe(user_name)
      db.execute("delete from users where name is '#{user_name}'")
    end
  end
end

# p DB.table_empty? 'users'
# p DB.table_exists? 'users'
# p DB.user_chat_ids
