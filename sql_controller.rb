require 'sqlite3'

class DBController
  attr_reader :db

  def initialize
    @db = SQLite3::Database.new('./test.db')
  end

  %w[title description game_url pictures_url available_from available_upto timestamp].each do |action|
    define_method(action + '_db_get') do |argument = nil|
      request = "select #{action} from free_games;" 
      # p argument.nil?
      db.execute argument.nil? ? request : request.sub(/;/, " where availability is '#{argument}';")
    end
  end
end
