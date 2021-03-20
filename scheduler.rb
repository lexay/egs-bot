require 'pry'
require_relative 'egscraper'
require_relative 'db_controller'

begin
  scraped_promotions = Parser::Promotions.run
rescue scraped_promotions.nil? || scraped_promotions.empty?
  sleep 5
  retry
end

DB.clear unless DB.table_empty?
DB.create if DB.table_empty?

scraped_promotions.each do |promotion|
  DB.insert FreeGame.new(promotion)
end
binding.pry
