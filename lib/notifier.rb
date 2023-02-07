module EGS
  class Notifier
    def initialize(bot = BOT)
      @bot = bot
    end

    def push(text, chat_id: ENV['TG_CHANNEL'])
      @bot.api.send_message(text:, chat_id:, parse_mode: 'html')
      LOG.info 'Games have been dispatched to the channel!'
    end
  end
end
