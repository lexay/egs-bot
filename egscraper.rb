require 'pry'
require 'hashie'
require 'json'
require 'net/http'
require 'time'
require 'yaml'
require_relative 'queries'

class Hash
  include Hashie::Extensions::DeepFind
end

class Array
  include Hashie::Extensions::DeepFind
end

class Promotion
  PROMO = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=RU&allowCountries=RU'.freeze
  GQL = 'https://www.epicgames.com/graphql'.freeze
  GAME_INFO_RU = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze
  GAME_INFO = 'https://store-content.ak.epicgames.com/api/en-US/content/products/'.freeze
  PRODUCT = 'https://www.epicgames.com/store/ru/product/'.freeze

  class Request
    class << self
      def get(uri_string, **options)
        uri = URI.parse(uri_string)
        request = Net::HTTP::Get.new(uri)

        request['Accept'] = 'application/json, text/plain, */*'
        request['Content-Type'] ||= options[:content]

        secure = { use_ssl: uri.scheme == 'https' }

        response = Net::HTTP.start(uri.hostname, uri.port, secure) do |http|
          http.request(request)
        end

        response.code == '200' ? JSON.parse(response.body) : []
      end

      def post(uri_string, **options)
        uri = URI.parse(uri_string)
        request = Net::HTTP::Post.new(uri)

        request['Accept'] = 'application/json, text/plain, */*'
        request['Content-Type'] ||= options[:content]
        request.body ||= options[:body]

        secure = { use_ssl: uri.scheme == 'https' }

        response = Net::HTTP.start(uri.hostname, uri.port, secure) do |http|
          http.request(request)
        end

        response.code == '200' ? JSON.parse(response.body) : []
      end
    end
  end

  class Parser
    class << self
      def run
        bootstrap current_free_games
      end

      private

      def all_promotions_get
        games = Request.get(PROMO, content: 'application/json;charset=utf-8')
        games.deep_find('elements') unless games.empty?
      end

      def current_free_games
        promoted_games = all_promotions_get
        promoted_games.select do |game|
          free_game = game.dig('promotions', 'promotionalOffers')
          next if free_game.nil?
          next if free_game.empty?

          game
        end
      end

      def bootstrap(games)
        ids = games.map { |game| id_get(game) }
        urls = url_get(ids)
        main_games = main_game_get(ids)
        parse(games, main_games, urls)
      end

      def parse(games, main_games, urls)
        parsed = []

        count = games.count

        0.upto(count - 1) do |idx|
          parsed.push(
            { start_date: date_get(games[idx], 'startDate'),
              end_date: date_get(games[idx], 'endDate'),
              pubs_n_devs: pubs_n_devs_get(games[idx]),
              title: title_get(main_games[idx]),
              short_description: description_get(main_games[idx], 'shortDescription'),
              full_description: description_get(main_games[idx], 'full_description'),
              game_uri: urls[idx],
              timestamp: Time.now }
          )
        end
        parsed
        binding.pry
      end

      def date_get(game, date)
        Time.parse game.deep_find(date)
      end

      def id_get(game)
        game['productSlug'].chomp('/home')[/[-[:alnum:]]+/] # %r{^[^\/]}
      end

      def pubs_n_devs_get(game)
        devs = game['customAttributes'].select do |attribute|
          attribute['key'] == 'developerName' ||
            attribute['key'] == 'publisherName'
        end
        devs.map { |dev_or_pub| dev_or_pub['value'] }.join(' / ')
      end

      def game_details_get(ids)
        games = []
        ids.each do |id|
          games.push Request.get(GAME_INFO_RU + id) if id
          sleep rand(0.75..1.5)
        end
        games
      end

      def main_game_get(ids)
        main_games_only = []
        games_and_addons = game_details_get(ids)
        games_and_addons.each do |game_or_addon|
          game_or_addon['pages'].each do |product|
            main_games_only.push product if product['type'] == 'productHome'
          end
        end
        main_games_only
      end

      def description_get(game, description)
        desc = game.deep_find(description) || '-'
        sanitize(desc)
      end

      def sanitize(description)
        description.delete! '*'
        description.delete! '#'
        pattern = /!?\[.+\)/
        description.partition(pattern).delete_if { |str| str =~ pattern }.join.strip
      end

      def title_get(game)
        game.deep_find('navTitle').strip
      end

      def url_get(ids)
        ids.map { |id| PRODUCT + id }
      end
    end
  end
end

Promotion::Parser.run
