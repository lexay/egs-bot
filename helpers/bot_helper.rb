module BotHelper
  def send_message(text, chat_id)
    EGS::BotClient.api.send_message(chat_id: chat_id, text: text, parse_mode: 'html')
  end
end
