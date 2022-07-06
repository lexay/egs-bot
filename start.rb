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
Dir['./helpers/*.rb', './lib/*.rb'].each { |f| require_relative f }

EGS::Schedule.new.run
EGS::TelegramService.new.listen
