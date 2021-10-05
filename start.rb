require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)

module EGS
  BotClient = Telegram::Bot::Client.new(ENV['T_TOKEN'])
  LOG = Logger.new($stdout)

  module Models
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Sequel.default_timezone = :utc
  end
end

require_relative 'helpers/time_helpers'
require_relative 'models/models'
Dir['./lib/*.rb'].each { |f| require_relative f }
# Dir['./lib/*.rb'].each(&method(:require_relative))

EGS::TelegramService.new.listen
EGS::Schedule.new.plan
