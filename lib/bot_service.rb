module EGS
  class TelegramService
    include BotHelper
    include GameHelper
    include TimeHelper

    def listen
      EGS::BotClient.run do |bot|
        bot.listen do |message|
          username = message.chat.username
          chat_id = message.chat.id
          case message
          when Telegram::Bot::Types::ChatMemberUpdated
            user_status = message.new_chat_member.status
            case user_status
            when 'member'
              EGS::Models::User.subscribe(username, chat_id)
              EGS::LOG.info "User: #{username}(#{chat_id}) is subscribed!"
              send_message(formatted_latest_games, chat_id)
            when 'kicked'
              EGS::Models::User.unsubscribe(chat_id)
              EGS::LOG.info "User: #{username}(#{chat_id}) is unsubscribed!"
            end
          when Telegram::Bot::Types::Message
            send_message(time_left, chat_id) if message.text == '/start'
          end
        end
      end
    end

    def time_left
      time = time_to_next_release
      time = time.positive? ? seconds_to_human_readable(time) : 'пока нет!'
      "Вы подписаны!\nСледующая раздача: #{time}"
    end
  end
end
