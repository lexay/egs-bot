# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

ruby '3.1.2'
gem 'activesupport', require: ['active_support/core_ext/string/filters',
                               'active_support/core_ext/string/inflections',
                               'active_support/core_ext/hash/keys']
gem 'hashie'
gem 'json'
gem 'logger'
gem 'net-http', require: 'net/http'
gem 'pg'
gem 'sequel'
gem 'telegram-bot-ruby', require: 'telegram/bot'
gem 'time'
gem 'yaml'

group :development do
  gem 'dotenv'
  gem 'pry'
  gem 'sqlite3'
end
