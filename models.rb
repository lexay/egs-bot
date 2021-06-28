require 'sequel'
require 'pry'

DB = Sequel.connect('sqlite://db/test.db')

class FreeGame < Sequel::Model
  def self.games(count = 1)
    order_by(:id).last(count)
  end

  def self.next_date
    games.last.end_date
  end
end

class User < Sequel::Model
  def self.chat_ids
    all.map(&:chat_id)
  end

  def unsubscribe(chat_id)
    where(chat_id: chat_id).delete
  end
end
