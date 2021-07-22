require_relative 'bot_service'
require_relative 'scheduler'

Schedule.new.plan
TelegramService.listen
