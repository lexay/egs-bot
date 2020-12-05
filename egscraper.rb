require 'yaml'
require 'time'
require 'net/http'
require 'json'
require_relative 'queries'

class FreeGames
  PROMO = 'https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=RU&allowCountries=RU'.freeze
  GQL = 'https://www.epicgames.com/graphql'.freeze
  GAME_INFO = 'https://store-content.ak.epicgames.com/api/ru/content/products/'.freeze
  PRODUCT = 'https://www.epicgames.com/store/ru/product/'.freeze

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
      slugs = slugs_get(free_games)
      # ids = slugs.map { |game| game.chomp('/home') } # %r{^[^\/]}
      ids = ['dungeons-3', 'mudrunner', 'assassins-creed-valhalla']
      game_info = game_info_get(ids)

      # titles = titles(game_info)
      # p titles
      # pubs_n_devs = pubs_n_devs_get(free_games)
      # p pubs_n_devs
      # dates = dates_get(free_games)
      # p dates
      # descriptions = descriptions_get(game_info)
      # p descriptions
      # price = price_get(free_games)
      # p price
      # ratings = ratings_get(ids)
      # p ratings
      # videos = videos_get(game_info)
      # p videos
      # images = images_get(game_info)
      # p images
      # languages = languages_get(game_info)
      # p languages
      # hw = hardwire_specs_get(game_info)
      # p hw
      hh = {
        titles: titles(game_info),
        pubs_n_devs: pubs_n_devs_get(free_games),
        dates: dates_get(free_games),
        descriptions: descriptions_get(game_info),
        urls: urls_get(ids),
        price: price_get(free_games),
        ratings: ratings_get(ids),
        videos: videos_get(game_info),
        images: images_get(game_info),
        languages: languages_get(game_info),
        hw: hardwire_specs_get(game_info)
      }
      p hh
      # testing tests
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
      devs.map { |dev| dev.map(&:values).flatten.join(' / ') }
    end

    def self.ratings_get(ids)
      ratings = []
      ids.each do |id|
        query = { query: RATINGS, variables: { sku: "EPIC_#{id}" } }.to_json
        ratings.push(
          Requests.post(GQL, body: query, content: 'application/json;charset=utf-8')
        )
        sleep rand(0.75..1.5)
      end
      score = ratings.map { |e| e.dig('data', 'OpenCritic', 'productReviews', 'openCriticScore') || '-' }
      percent = ratings.map { |e| e.dig('data', 'OpenCritic', 'productReviews', 'percentRecommended') || '-' }
      [score, percent].transpose
    end

    def self.game_info_get(ids)
      games = []
      ids.each do |id|
        games.push Requests.get(GAME_INFO + id)
        sleep rand(0.75..1.5)
      end
      games
    end

    def self.refs_get(game_info)
      refs = []
      game_info.each do |game|
        game_ref = game['pages'].map do |page|
          page['data']['carousel']['items'].first['video']['recipes'] || nil
        end.join
        refs.push YAML.safe_load(game_ref)
      end
      en_refs = refs.map { |ref| ref['en-US'] unless ref.nil? }
      webm = en_refs.map { |game| game&.select { |ref| ref['recipe'] == 'video-webm' } }
      webm.map { |game| game&.map { |webm_ref| webm_ref['mediaRefId'] } }
    end

    def self.videos_get(game_info)
      videos = []
      media_refs = refs_get(game_info).flatten
      media_refs.each do |ref|
        if ref.nil?
          videos.push ref
          next
        end

        query = { query: MEDIA, variables: { mediaRefId: ref } }.to_json
        videos.push(
          Requests.post(GQL, body: query, content: 'application/json;charset=utf-8')
        )
        sleep rand(0.75..1.5)
      end
      all_res_videos = videos.map { |e| e&.dig('data', 'Media', 'getMediaRef', 'outputs') }
      high_res_videos = all_res_videos.map { |video| video&.find_all { |e| e['key'] == 'high' } }.flatten
      high_res_videos.map { |video| video['url'] unless video.nil? }
    end

    def self.descriptions_get(game_info)
      descriptions = []
      game_info.each do |e|
        descriptions.push full_desc: e['pages'].first.dig('data', 'about', 'description') || 'Отсутствует'
        descriptions.push short_desc: e['pages'].first.dig('data', 'about', 'shortDescription')
      end
      descriptions
    end

    def self.images_get(game_info)
      images = []
      game_info.each do |e|
        images.push e['pages'].first['_images_']
      end
      images
    end

    def self.requirements_get(game_info)
      game_info.map { |e| e['pages'].first['data']['requirements'] }
    end

    def self.languages_get(game_info)
      requirements_get(game_info).map { |e| e['languages'].join.strip }
    end

    def self.hardwire_specs_get(game_info)
      requirements_fmt = String.new
      requirements = requirements_get(game_info).map { |e| e['systems'] }
      os_types = requirements.map { |os| os.map { |spec| spec['systemType'] } }.flatten
      req_details = requirements.map { |os| os.map { |spec| spec['details'] } }.flatten(1)
      req_details.each_with_index do |os, i|
        requirements_fmt << os_types[i] + "\n" 
        os.each do |spec|
          title = spec['title']
          min = spec['minimum']
          rec = spec['recommended']
          # if title == 'Место на диске' && /\d$/.match(rec)
          #   rec + 'ГБ'
          # elsif title == 'Место на диске' && /\d$/.match(min)
          #   min + 'ГБ'
          # end
          if min == rec
            requirements_fmt << (title + ': ' + rec) << "\n"
          elsif min && (!rec || rec.empty?)
            requirements_fmt << (title + ': ' + min) << "\n"
          elsif rec && (!min || min.empty?)
            requirements_fmt << (title + ': ' + rec) << "\n"
          else
            requirements_fmt << (title + ': ' + min + ' | ' + rec) << "\n"
          end
        end
        requirements_fmt << "\n"
      end
      requirements_fmt.split("\n\n")
    end


    def self.dates_get(games)
      games.map do |game|
        promo = game['promotions'].values.flatten.first['promotionalOffers'].first
        to_msk = proc { |date| (Time.parse(date) + 60 * 60 * 3).strftime('%d/%m/%Y %H:%M MSK') }
        [promo['startDate'], promo['endDate']].map(&to_msk)
      end
    end

    def self.titles(game_info)
      game_info.map { |game| game['productName'] }
    end

    def self.urls_get(ids)
      ids.map { |id| PRODUCT + id }
    end
  end
end

FreeGames::Attributes.runner
# Social?
