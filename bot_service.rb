require 'dotenv/load'
require 'logger'
require 'pry'
require 'telegram/bot'
require_relative 'db_controller'

module TelegramService
  BOT = Telegram::Bot::Client.new(ENV['T_TOKEN'])
  class << self
    def listen
      logger = Logger.new(STDOUT)
      BOT.run do |current_bot|
        current_bot.listen do |message|
          binding.pry
          case message
          when Telegram::Bot::Types::ChatMemberUpdated
            user_status = message.new_chat_member.status
            # BOT.api.get_chat_member(chat_id: message.chat.id, user_id: message.from.id)
            case user_status
            when 'member'
              DB.insert User.new(name: message.chat.username, chat_id: message.chat.id, timestamp: Time.now.to_s)
              logger.info "User: #{message.from.username}(#{message.chat.id}) is subscribed!"
            when 'kicked'
              DB.unsubscribe message.chat.id
              logger.info "User: #{message.from.username}(#{message.chat.id}) is unsubscribed!"
            end
          when Telegram::Bot::Types::Message
            BOT.api.send_message(chat_id: message.chat.id, text: time_left) if message.text == '/start'
          end
        end
      end
    end

    def time_left
      games = DB.games
      # binding.pry
      if games.empty?
        puts 'Следующая раздача неизвестна!'
        return
      end
      game = games.first
      days_in_sec = (Time.parse(game.end_date) - Time.now).to_i
      days, hours_in_sec = days_in_sec.divmod(60 * 60 * 24)
      hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
      minutes, seconds = minutes_in_sec.divmod(60)
      "Вы подписаны!\n" \
      "Следующая раздача через: #{days} дн.: #{hours} ч.: #{minutes} м.: #{seconds} с."
    end
  end
end

# TeleBot.listen
