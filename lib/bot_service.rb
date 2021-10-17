module EGS
  class TelegramService
    include BotHelper
    include GameHelper
    include TimeHelper

    def listen
      EGS::BotClient.run do |bot|
        bot.listen do |message|
          case message
          when Telegram::Bot::Types::ChatMemberUpdated
            user_status = message.new_chat_member.status
            # BotClient.api.get_chat_member(chat_id: message.chat.id, user_id: message.from.id)
            case user_status
            when 'member'
              EGS::Models::User.subscribe(message.chat.username, message.chat.id)
              EGS::LOG.info "User: #{message.from.username}(#{message.chat.id}) is subscribed!"
              send_message(formatted_latest_games, message.chat.id)
            when 'kicked'
              EGS::Models::User.unsubscribe(message.chat.id)
              EGS::LOG.info "User: #{message.from.username}(#{message.chat.id}) is unsubscribed!"
            end
          when Telegram::Bot::Types::Message
            send_message(time_left, message.chat.id) if message.text == '/start'
          end
        end
      end
    end

    def time_left
      date = seconds_to_human_readable(time_to_next_release)
      "Вы подписаны!\nСледующая раздача через: #{date}"
    end
  end
end
