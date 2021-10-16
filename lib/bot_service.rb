module EGS
  class TelegramService
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
              latest_games = EGS::Models::Release.last.free_games
              formatted_latest_games = latest_games.empty? ? 'Раздача неизвестна!' : Template.new(latest_games)
              EGS::BotClient.api.send_message(chat_id: message.chat.id, text: formatted_latest_games)
            when 'kicked'
              EGS::Models::User.unsubscribe(message.chat.id)
              EGS::LOG.info "User: #{message.from.username}(#{message.chat.id}) is unsubscribed!"
            end
          when Telegram::Bot::Types::Message
            EGS::BotClient.api.send_message(chat_id: message.chat.id, text: time_left) if message.text == '/start'
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
