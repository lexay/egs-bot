require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)
system('rake', 'db:migrate')
module EGS
  TG_BOT = Telegram::Bot::Client.new(ENV['T_TOKEN'])
  DB = Sequel.connect(ENV['DATABASE_URL'])
  Sequel.default_timezone = :utc
  I18n.load_path << Dir[File.expand_path('config/locales') + '/*.yml']
  I18n.default_locale = :ru
  LOG = Logger.new($stdout)
end

require_relative 'db/models/models'
Dir['./helpers/*.rb', './lib/*.rb'].each { |f| require_relative f }

EGS::Schedule.new.run
