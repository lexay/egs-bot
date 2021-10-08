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
              EGS::Models::User.new(name: message.chat.username, chat_id: message.chat.id, timestamp: Time.now).save
              EGS::LOG.info "User: #{message.from.username}(#{message.chat.id}) is subscribed!"
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
      return 'Следующая раздача неизвестна!' unless release_date_ahead?

      days_in_sec = time_to_next_release.to_i
      days, hours_in_sec = days_in_sec.divmod(60 * 60 * 24)
      hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
      minutes, seconds = minutes_in_sec.divmod(60)
      "Вы подписаны!\n" \
      "Следующая раздача через: #{days} дн.: #{hours} ч.: #{minutes} м.: #{seconds} с."
    end
  end
end
