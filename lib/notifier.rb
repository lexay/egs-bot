module EGS
  class Notifier
    def self.push(text, chat_id: ENV['TG_CHANNEL'])
      BOT.api.send_message(text:, chat_id:, parse_mode: 'html')
      LOG.info 'Games have been dispatched to the channel!'
    end
  end
end
