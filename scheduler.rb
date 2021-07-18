require 'logger'
require_relative 'bot_service'
require_relative 'models'
require_relative 'egscraper'
require_relative 'template'

module Schedule
  class << self
    def plan
      Thread.new do
        logger = Logger.new($stdout)
        loop do
          games = parse
          if games.empty?
            logger.info 'Games returned nothing! Skipping...'
          else
            store(games)
            logger.info 'Games have been successfully saved to Database!'
          end
          chat_ids = User.chat_ids
          if chat_ids.empty?
            logger.info 'No subscribed users! Skipping...'
          else
            dispatch(games.count, chat_ids, logger)
          end
          wait
        end
      end
    end

    private

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
        FreeGame.new(game).save
      end
    end

    def dispatch(count, chat_ids, logger)
      games = FreeGame.games(count)

      chat_ids.each do |chat_id|
        TelegramService::BOT.api.send_message(chat_id: chat_id, text: Template.new(games), parse_mode: 'html')
        logger.info "Games have been dispatched to #{chat_id}!"

      # Telegram::Bot::Exceptions::ResponseError
      # Telegram API has returned the error. (ok: "false", error_code: "403",
      # description: "Forbidden: bot was blocked by the user")

      rescue => exception 
        logger.error exception.message

        if process(exception)[:error_code] == '403'
          logger.info "Invalid user(#{chat_id}). Unsubscribing..."
          User.unsubscribe chat_id
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
      next_date = FreeGame.next_date
      day = 60 * 60 * 24
      return sleep day if next_date.nil?

      next_date -= Time.now
      sleep next_date.negative? ? day : next_date
    end
  end
end
