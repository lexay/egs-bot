require 'sqlite3'
require_relative 'db_model'

module DB
  class << self
    def db
      SQLite3::Database.new('./test.db', results_as_hash: true)
    end

    def insert(game)
      db.execute("insert into free_games (id, title, short_description, full_description,
                  pubs_n_devs, price, hardware, videos, languages, rating, game_uri,
                  start_date, end_date, available, timestamp)
                  values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                  game.id, game.title, game.short_description, game.full_description,
                  game.pubs_n_devs, game.price, game.hardware, game.videos,
                  game.languages, game.rating, game.game_uri, game.start_date,
                  game.end_date, game.available, game.timestamp)
    end

    def table_empty?
      db.execute("select name from sqlite_master where type='table'").empty?
    end

    def create
      table_new = <<~SQL
        create table free_games (
          id integer,
          title string,
          full_description text,
          short_description text,
          pubs_n_devs string,
          price integer,
          hardware text,
          videos text,
          languages text,
          rating text,
          game_uri string,
          start_date string,
          end_date string,
          available string,
          timestamp string);
      SQL
      db.execute(table_new)
    end

    def clear
      db.execute('drop table free_games;')
    end

    def get(availability)
      games = db.execute("select * from free_games where available is '#{availability}';")
      games.map! { |game| game.transform_keys(&:to_sym) }
      games.map! { |game| FreeGame.new(game) }
    end

    # %w[id start_date end_date pubs_n_devs price title full_description short_description
    #    hardware videos languages rating game_uri timestamp available].each do |action|
    #   define_method(action + '_db_get') do |argument = nil|
    #     request = "select #{action} from free_games;"
    #     db.execute argument.nil? ? request : request.sub(/;/, " where availability is '#{argument}';")
    #   end
    # end
  end
end
