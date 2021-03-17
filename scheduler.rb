require 'pry'
require_relative 'db_model'
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

scraped_promotions.each_with_index do |promotion, idx|
  game = FreeGame.new(promotion)
  DB.insert(idx, game.title, game.short_description, game.full_description,
            game.pubs_n_devs, game.price, game.hardware, game.videos, game.languages,
            game.rating, game.game_uri, game.start_date, game.end_date, game.available, Time.now.to_s)
end
binding.pry
