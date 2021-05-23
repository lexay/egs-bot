require 'dotenv/load'
require 'telegram/bot'
require 'pry'
require_relative 'db_controller'

module TeleBot
  class << self
    def bot
      Telegram::Bot::Client.new(ENV['T_TOKEN'])
    end
    def listen
      bot.run do |current_bot|
        current_bot.listen do |message|
          # binding.pry
          case message
          when Telegram::Bot::Types::ChatMemberUpdated
            user_status = message.new_chat_member.status
            puts user_status
            if user_status == 'member'
              DB.insert User.new(name: message.chat.username, chat_id: message.chat.id, timestamp: Time.now.to_s)
            else
              DB.unsubscribe message.chat.username
            end
          when Telegram::Bot::Types::Message
            bot.api.send_message(chat_id: message.chat.id, text: time_left) if message.text == '/start'
          end
        end
      end
    end

    def time_left
      games = DB.get
      game = games.first
      days_in_sec = (Time.parse(game.end_date) - Time.now).to_i
      days, hours_in_sec = days_in_sec.divmod(60 * 60 * 24)
      hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
      minutes, seconds = minutes_in_sec.divmod(60)
      "Вы подписаны!\n" \
      "Следующая раздача через: #{days} д., #{hours} ч., #{minutes} м., #{seconds} с."
    end

    def mini_logger(current_message)
      puts "Username: #{current_message.from.username}, Command: #{current_message.text}"
      puts "Date: #{Time.at(current_message.date)}"
    end
  end
end

# TeleBot.listen
