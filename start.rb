require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)

module EGS
  BOT ||= Telegram::Bot::Client.new(ENV['T_TOKEN'])
  LOG = Logger.new($stdout)
  module Models
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Sequel.default_timezone = :utc
  end
end

require_relative 'bot_service'
require_relative 'scheduler'

thread1 = Thread.new { EGS::Schedule.new.plan }
thread2 = Thread.new { EGS::TelegramService.new.listen }
[thread1, thread2].each(&:join)
