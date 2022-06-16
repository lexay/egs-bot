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
            when 'kicked'
              EGS::Models::User.unsubscribe(chat_id)
              EGS::LOG.info "User: #{username}(#{chat_id}) is unsubscribed!"
            end
          when Telegram::Bot::Types::Message
            show_release(chat_id) if message.text == '/start'
          end
        end
      end
    end

    def show_release(chat_id)
      time = time_to_next_release
      if time.positive?
        time = seconds_to_human_readable(time)
        send_message(formatted_latest_games, chat_id)
      else
        time = I18n.t(:time_unknown)
      end
      notification = I18n.t(:subbed, time: time)
      send_message(notification, chat_id)
    end
  end
end
