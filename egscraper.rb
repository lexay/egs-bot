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

        JSON.parse(response.body)
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

        JSON.parse(response.body)
      end
    end
  end

  class Promotions
    class << self
      def all
        games = Requests.get(PROMO, content: 'application/json;charset=utf-8')
        games.deep_find('elements')
      end

      def current
        free_games = Promotions.all
        free_games.select { |game| game unless game['promotions'].nil? }
      end

      def run
        promotions = Promotions.current
        bootstrap(promotions)
      end

      private

      def bootstrap(promotions)
        first_part = first_part_get(promotions)
        ids = promotions.map { |game| ids_get(game) }
        ratings = ratings_get(ids)
        uris = game_uris_get(ids)
        main_games = main_games_get(ids)
        second_part = second_part_get(main_games)
        first_part.map.with_index do |hash, idx|
          hash.merge(second_part[idx], ratings[idx], uris[idx], id: idx, timestamp: Time.now.to_s)
        end
      end

      def first_part_get(promotions)
        promotions.map do |game|
          hh = {}
          %w[start_date end_date pubs_n_devs price available].each do |name|
            hh[name.to_sym] = method(name << '_get').call(game)
          end
          hh
        end
      end

      def second_part_get(main_games)
        main_games.map do |game|
          hh = {}
          %w[title full_description short_description hardware videos languages].each do |name|
            hh[name.to_sym] = method(name << '_get').call(game)
          end
          hh
        end
      end

      def start_date_get(game)
        game.deep_find('startDate')
      end

      def end_date_get(game)
        game.deep_find('endDate')
      end

      def ids_get(game)
        game['productSlug'].chomp('/home')[/[-[:alnum:]]+/]
      end

      def price_get(game)
        original_price = game.deep_find('originalPrice')
        original_price.positive? ? original_price / 100 : 'Пока неизвестна'
      end

      def pubs_n_devs_get(game)
        devs = game['customAttributes'].select do |attribute|
          attribute['key'] == 'developerName' ||
            attribute['key'] == 'publisherName'
        end
        devs.map { |dev_or_pub| dev_or_pub['value'] }.join(' / ')
      end

      def available_get(game)
        Time.parse(start_date_get(game)) - Time.now > 0 ? 'next' : 'now'
      end

      def ratings_get(ids)
        ratings = []
        ids.each do |id|
          query = { query: RATINGS, variables: { sku: "EPIC_#{id}" } }.to_json
          request = Requests.post(GQL, body: query, content: 'application/json;charset=utf-8')
          score = (request.deep_find('openCriticScore') || '-').to_s
          percent = request.deep_find('percentRecommended')
          percent = percent.nil? ? '-' : percent.to_s << '%'

          ratings.push({ rating: score << '/' << percent })
          sleep rand(0.75..1.5)
        end
        ratings
      end

      def game_info_get(ids)
        games = []
        ids.each do |id|
          games.push Requests.get(GAME_INFO_RU + id) if id
          sleep rand(0.75..1.5)
        end
        games
      end

      def main_games_get(ids)
        main_games = []
        games = game_info_get(ids)
        games.each do |game|
          game['pages'].each do |product|
            main_games.push product if product['type'] == 'productHome'
          end
        end
        main_games
      end

      def refs_get(game)
        refs = game.deep_find('recipes')
        refs.nil? ? (return refs) : refs_fmt = YAML.safe_load(refs)

        en_refs = refs_fmt['en-US']
        webm = en_refs.select { |ref| ref['recipe'] =~ /video-webm/ }.first
        webm['mediaRefId']
      end

      def videos_get(game)
        media_ref = refs_get(game)
        return '-' if media_ref.nil?

        query = { query: MEDIA, variables: { mediaRefId: media_ref } }.to_json
        request = Requests.post(GQL, body: query, content: 'application/json;charset=utf-8')
        sleep rand(0.75..1.5)
        request.deep_find('url')
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
        description.partition(pattern).delete_if { |str| str =~ pattern }.join
      end

      def images_get(game)
        images = []
        cover_image = game.deep_find('_images_').find_all { |image| /\.png$/.match(image) }.first
        images.push cover_image
        images
      end

      def languages_get(game)
        game.deep_find('languages').join
      end

      def hardware_get(game)
        requirements_fmt = String.new
        os_types = game.deep_find_all('systemType')
        details = game.deep_find_all('details')
        details.each_with_index do |os, idx|
          requirements_fmt << os_types[idx] << "\n"
          os.each do |spec|
            title = spec['title']
            min = spec['minimum']
            rec = spec['recommended']

            if min == rec
              requirements_fmt << (title << ': ' << rec) << "\n"
            elsif min && (!rec || rec.empty?)
              requirements_fmt << (title << ': ' << min) << "\n"
            elsif rec && (!min || min.empty?)
              requirements_fmt << (title << ': ' << rec) << "\n"
            else
              requirements_fmt << (title << ': ' << min << ' | ' << rec) << "\n"
            end
          end
          requirements_fmt << "\n"
        end
        requirements_fmt #.split("\n\n")
      end

      def title_get(game)
        game.deep_find('navTitle').strip
      end

      def game_uris_get(ids)
        ids.map { |id| { game_uri: PRODUCT + id } }
      end
    end
  end
end

