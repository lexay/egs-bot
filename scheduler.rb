require 'pry'
require_relative 'bot_service'
require_relative 'egscraper'
require_relative 'db_controller'
require_relative 'template'

module Scheduler
  def self.run
    begin
      scraped_promotions = Parser::Promotions.run
    rescue scraped_promotions.nil? || scraped_promotions.empty?
      sleep 5
      retry
    end

    DB.clear 'free_games' if DB.table_exists? 'free_games'
    DB.create 'free_games' unless DB.table_exists? 'free_games'

    scraped_promotions.each do |promotion|
      DB.insert FreeGame.new(promotion)
    end

    Thread.new do
      loop do
        sender
      end
    end
  end

  def self.sender
    ids = DB.user_chat_ids
    games = DB.get
    ids.each do |chat_id|
      TeleBot.bot.api.send_message(chat_id: chat_id, text: Template.make(games), parse_mode: 'html')
    end
    sleep (Time.parse(games.first.end_date) - Time.now).to_i
  end
end
