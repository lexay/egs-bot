require 'time'
require 'net/http'
require 'json'
require_relative 'queries'

class FreeGames
  PROMO = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=RU&allowCountries=RU'.freeze
  GQL = 'https://www.epicgames.com/graphql'.freeze
  GAME_INFO = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze

  def self.games_get
    games_hash = Requests.get(PROMO, content: 'application/json;charset=utf-8')
    games_hash.dig('data', 'Catalog', 'searchStore', 'elements')
  end

  class Requests
    def self.get(uri_string, **options)
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

    def self.post(uri_string, **options)
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

  class Attributes
    def self.runner
      free_games = FreeGames.games_get
      dates = dates_get(free_games)
      p dates
      slugs = slugs_get(free_games)
      pubs_n_devs = pubs_n_devs_get(free_games)
      price = price_get(free_games)
      # ids = slugs.map { |game| game.chomp('/home') } # %r{^[^\/]}
      # p ids
      # pubs_n_devs = pubs_n_devs_get(free_games)
      # game_info = game_info_get(ids)
      # ratings = ratings_get(ids)
      # videos = videos_get(game_info)
      # descriptions = descriptions_get(game_info)
      # images = images_get(game_info)
      # languages = languages_get(game_info)
      # p hardwire_specs_get(game_info)
      # {
      #   slugs: slugs,
      #   pubs_n_devs: pubs_n_devs,
      #   price: price,
      #   ratings: ratings,
      #   videos: videos,
      #   descriptions: descriptions,
      #   images: images,
      #   requirements: requirements
      # }
    end

    def self.slugs_get(games)
      games.map { |game| game['productSlug'] }
    end

    def self.price_get(games)
      games.map do |game|
        game.dig('price', 'totalPrice', 'fmtPrice', 'originalPrice')
      end
    end

    def self.pubs_n_devs_get(games)
      devs = games.map do |game|
        dev_hash = game['customAttributes'].map { |split_hash| [split_hash.values].to_h }
        dev_hash.find_all { |dev| dev['developerName'] || dev['publisherName'] }
      end
      devs.map { |dev| dev.map(&:values).flatten.join(' - ') }
    end

    def self.ratings_get(ids)
      list = []
      ids.each do |id|
        query = { query: RATINGS, variables: { id: "EPIC_#{id}" } }.to_json
        list.push(
          Requests.post(GQL, body: query, content: 'application/json;charset=utf-8')
        )
        sleep rand(0.75..1.5)
      end
      list
    end

    def self.game_info_get(ids)
      list = []
      ids.each do |id|
        list.push Requests.get(GAME_INFO + id)
        sleep rand(0.75..1.5)
      end
      list
    end

    def self.refs_get(game_info)
      list = []
      game_info.each do |ref|
        ref_fmt = ref['pages'].first['data']['carousel']['items'].first['video']['recipes']
        list.push ref_fmt.scan(/(?<=mediaRefId\": \")\w+(?=\")/) unless ref_fmt.nil?
      end
      list
    end

    def self.videos_get(game_info)
      list = []
      media_refs = refs_get(game_info).flatten
      media_refs.each do |ref|
        query = { query: MEDIA, variables: { mediaRefId: ref } }.to_json
        list.push(
          Requests.post(GQL, body: query, content: 'application/json;charset=utf-8')
        )
        sleep rand(0.75..1.5)
      end
      videos = list.map { |e| e.dig('data', 'Media', 'getMediaRef', 'outputs') }.flatten
      videos.find_all { |e| e['url'] if e['key'] == 'high' && e['contentType'] == 'video/webm' }
    end

    def self.descriptions_get(game_info)
      list = []
      game_info.each do |e|
        list.push full_desc: e['pages'].first.dig('data', 'about', 'description')
        list.push short_desc: e['pages'].first.dig('data', 'about', 'shortDescription')
      end
      list
    end

    def self.images_get(game_info)
      list = []
      game_info.each do |e|
        list.push e['pages'].first['_images_']
      end
      list
    end

    def self.requirements_get(game_info)
      game_info.map { |e| e['pages'].first['data']['requirements'] }
    end

    def self.languages_get(game_info)
      requirements_get(game_info).map { |e| e['languages'].join.strip }
    end

    def self.hardwire_specs_get(game_info)
      str = String.new
      requirements = requirements_get(game_info).map { |e| e['systems'] }
      os_types = requirements.map { |os| os.map { |spec| spec['systemType'] } }.flatten
      req_details = requirements.map { |os| os.map { |spec| spec['details'] } }.flatten(1)
      req_details.each_with_index do |os, i|
        str << os_types[i] + "\n" 
        os.each do |spec|
          title = spec['title']
          min = spec['minimum']
          rec = spec['recommended']
          if min == rec || min.nil?
            str << (title + ': ' + rec) << "\n"
          elsif rec.empty?
            str << (title + ': ' + min) << "\n"
          else
            str << (title + ': ' + min + ' | ' + rec) << "\n"
          end
        end
        str << "\n"
      end
      str.split("\n\n")
    end


    def self.dates_get(games)
      games.map do |game|
        promo = game['promotions'].values.flatten.first['promotionalOffers'].first
        to_msk = proc { |date| (Time.parse(date) + 60 * 60 * 3).strftime('%d/%m/%Y %H:%M MSK') }
        [promo['startDate'], promo['endDate']].map(&to_msk)
      end
    end

    # parse ratings
  end
end

FreeGames::Attributes.runner
