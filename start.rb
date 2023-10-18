require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)
system('rake', 'db:migrate')

module EGS
  Sequel.connect(ENV['DATABASE_URL'])
  Sequel.default_timezone = :utc
  I18n.load_path << Dir[File.expand_path('config/locales') + '/*.yml']
  I18n.default_locale = :ru
  BOT = Telegram::Bot::Client.new(ENV['TG_TOKEN'])
  LOG = Logger.new($stdout)
end

Dir['db/models/models.rb', './helpers/*.rb', './lib/*.rb'].each { |f| require_relative f }

EGS::Scheduler.run
