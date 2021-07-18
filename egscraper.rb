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

class Parser
  PROMO = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=RU&allowCountries=RU'.freeze
  GQL = 'https://www.epicgames.com/graphql'.freeze
  GAME_INFO_RU = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze
  GAME_INFO = 'https://store-content.ak.epicgames.com/api/en-US/content/products/'.freeze
  PRODUCT = 'https://www.epicgames.com/store/ru/product/'.freeze

  class Requests
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

  class Promotions
    class << self
      def all
        games = Requests.get(PROMO, content: 'application/json;charset=utf-8')
        games.deep_find('elements') unless games.empty?
      end

      def current
        free_games = Promotions.all
        free_games.select do |game|
          current_promotion = game.dig('promotions', 'promotionalOffers')
          next if current_promotion.nil?
          next if current_promotion.empty?

          game
        end
      end

      def run
        promotions = Promotions.current
        bootstrap(promotions)
      end

      private

      def bootstrap(promotions)
        ids = promotions.map { |game| id_get(game) }
        urls = url_get(ids)
        main_games = main_game_get(ids)
        first_part = parse(promotions, %w[start_date end_date pubs_n_devs])
        second_part = parse(main_games, %w[title full_description short_description])
        first_part.map.with_index do |hash, idx|
          hash.merge(second_part[idx], urls[idx], timestamp: Time.now)
        end
      end

      def parse(games, attributes)
        games.map do |game|
          info = {}
          attributes.each do |name|
            info[name.to_sym] = method(name + '_get').call(game)
          end
          info
        end
      end

      def start_date_get(game)
        Time.parse game.deep_find('startDate')
      end

      def end_date_get(game)
        Time.parse game.deep_find('endDate')
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
          games.push Requests.get(GAME_INFO_RU + id) if id
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

      def short_description_get(game)
        desc = game.deep_find('shortDescription') || '-'
        sanitize(desc)
      end

      def full_description_get(game)
        desc = game.deep_find('description') || '-'
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
        ids.map { |id| { game_uri: PRODUCT + id } }
      end
    end
  end
end
