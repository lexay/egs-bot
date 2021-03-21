require 'dotenv/load'
require 'telegram/bot'
require_relative 'bot_commands'

module TeleBot
  class << self
    def listen
      Telegram::Bot::Client.run(ENV['T_TOKEN']) do |bot|
        bot.listen do |message|
          mini_logger(message)
          case message.text
          when '/now'
            bot.api.send_message(chat_id: message.chat.id, text: BotCommand.now, parse_mode: 'HTML')
          when '/next'
            bot.api.send_message(chat_id: message.chat.id, text: BotCommand.next, parse_mode: 'HTML')
          when '/help'
            bot.api.send_message(chat_id: message.chat.id, text: BotCommand.help, parse_mode: 'HTML')
          else
            bot.api.send_message(chat_id: message.chat.id, text: BotCommand.message_missing(message))
            bot.api.send_message(chat_id: message.chat.id, text: BotCommand.help, parse_mode: 'HTML')
          end
        end
      end
    end

    def mini_logger(current_message)
      puts "Username: #{current_message.from.username}, Command: #{current_message.text}"
      puts "Date: #{Time.at(current_message.date)}"
    end
  end
end

TeleBot.listen
