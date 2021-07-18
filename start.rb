require_relative 'bot_service'
require_relative 'scheduler'

Schedule.plan
TelegramService.listen
