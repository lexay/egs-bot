module EGS
  class Notifier
    def self.push(text, chat_id: ENV['TG_CHANNEL'])
      BOT.api.send_message(text:, chat_id:, parse_mode: 'html')
    end
  end
end
