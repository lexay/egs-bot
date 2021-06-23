require 'logger'
require 'pry'
require_relative 'bot_service'
require_relative 'db_controller_new'
require_relative 'egscraper'
require_relative 'template'

module Schedule
  class << self
    def plan
      create(:free_games, :users)

      Thread.new do
        logger = Logger.new($stdout)
        loop do
          games = parse
          store(games)
          # binding.pry
          send(games.count, logger)
          wait
        end
      end
    end

    private

    def create(*tables)
      # DB.clear table if DB.table_exists? table
      tables.each do |table|
        DB.create table unless DB.table_exists? table
      end
    end

    def parse
      5.times do
        promotions = Parser::Promotions.run
        return promotions unless promotions.empty?

        sleep rand(20..30)
      end
      []
    end

    def store(games)
      games.each do |game|
        DB.insert FreeGame.new(game)
      end
    end

    def send(count, logger)
      games = DB.games(count)
      if games.empty?
        logger.info 'Games returned nothing! Skipping...'
        return
      end

      chat_ids = DB.chat_ids
      if chat_ids.empty?
        logger.info 'No subscribed users! Skipping...'
        return
      end

      # chat_ids.each do |chat_id|
      #   chat_member = TelegramService::BOT.api.get_chat_member(chat_id: chat_id, user_id: chat_id)
      #   binding.pry
      # end

      chat_ids.each do |chat_id|
        TelegramService::BOT.api.send_message(chat_id: chat_id, text: Template.new(games), parse_mode: 'html')

      # Telegram::Bot::Exceptions::ResponseError
      # Telegram API has returned the error. (ok: "false", error_code: "403",
      # description: "Forbidden: bot was blocked by the user")

      rescue => exception 
        logger.error exception.message

        if process(exception)[:error_code] == '403'
          logger.info 'Invalid user. Unsubscribing...'
          DB.unsubscribe(chat_id) 
        end

        next
      end
    end

    def process(exception)
      message = exception.message.match(/(?<=\().+(?=\))/).to_s
      message
        .split(',')
        .to_h { |k_v_pair| [k_v_pair[/\w+[^:]/], k_v_pair[/(?<=\").+[^"]/]] }
        .transform_keys(&:to_sym)
    end

    def wait
      next_date = DB.games.first.end_date
      next_date = next_date.nil? ? 60 * 60 * 24 : Time.parse(next_date) - Time.now
      sleep next_date
    end
  end
end
# 370506028 - Ferm[yasha]
