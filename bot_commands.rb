require_relative 'template'
require_relative 'db_controller'

class BotCommand
  class << self
    def now
      current_games = DB.get('now')
      Template.make current_games
    end

    def next
      next_games = DB.get('next')
      Template.make next_games
    end

    def help
      <<~MESSAGE
        <strong>Команды:</strong>

        /help - справочная информация (это меню)
        /now - релизы текущей недели
        /next - релизы следующей недели
      MESSAGE
    end

    def message_missing(message)
      "#{message.from.first_name}, не понял команду ! Повторите!"
    end
  end
end
