module EGS
  class Promotion
    class Request
      def self.get(uri_string, **options)
        uri = URI.parse(uri_string)
        req = Net::HTTP::Get.new(uri)

        req['accept'] = 'application/json, text/plain, */*'
        req['content-type'] = 'application/json'
        req['user-agent'] = ENV['USER_AGENT']

        secure = { use_ssl: uri.scheme == 'https' }

        res = Net::HTTP.start(uri.hostname, uri.port, secure) do |http|
          http.request(req)
        end

        case res
        when Net::HTTPOK
          hash = JSON.parse(response.body)
          hash.deep_transform_keys { |key| key.underscore.to_sym }
        else
          LOG.info "Response has returned #{res.code}, #{res.body} from #{uri} ..."
          Hash.new
        end
      end

      def self.post(uri_string, **options)
        uri = URI.parse(uri_string)
        req = Net::HTTP::Post.new(uri)

        req['accept'] = 'application/json, text/plain, */*'
        req['content-type'] = 'application/json'
        req['user-agent'] = ENV['USER_AGENT']

        req.body = format(GQL_CATALOG,
                          options.dig(:namespace),
                          options.dig(:id),
                          options.dig(:locale))

        secure = { use_ssl: uri.scheme == 'https' }

        res = Net::HTTP.start(uri.hostname, uri.port, secure) do |http|
          http.request(req)
        end

        case res
        when Net::HTTPOK
          JSON
            .parse(res.body)
            .first
            .deep_transform_keys { |key| key.underscore.to_sym }
        else
          LOG.info "Response has returned #{res.code}, #{res.body} from #{uri} ..."
          Hash.new
        end
      end
    end
  end
end
