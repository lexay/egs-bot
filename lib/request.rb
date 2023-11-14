module EGS
  class Request
    def self.get(uri_string, **_options)
      uri = URI.parse(uri_string)
      req = Net::HTTP::Get.new(uri)

      req['accept'] = 'application/json, text/plain, */*'
      req['content-type'] = 'application/json;charset=utf-8'
      req['user-agent'] = ENV['USER_AGENT']

      secure = { use_ssl: uri.scheme == 'https' }

      Net::HTTP.start(uri.hostname, uri.port, secure) do |http|
        http.request(req)
      end
    end
  end
end
