require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)

module EGS
  BotClient = Telegram::Bot::Client.new(ENV['T_TOKEN'])
  LOG = Logger.new($stdout)
  I18n.load_path << Dir[File.expand_path('config/locales') + '/*.yml']
  I18n.default_locale = :ru

  module Models
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Sequel.default_timezone = :utc
  end
end

require_relative 'db/models/models'
Dir['./helpers/*.rb'].each { |f| require_relative f }
Dir['./lib/*.rb'].each { |f| require_relative f }
# Dir['./lib/*.rb'].each(&method(:require_relative))

EGS::Schedule.new.plan
EGS::TelegramService.new.listen
