module FCC4D
  class Client
    def initialize options = {}
      @auth_token = options[:auth_token]
      @username = options[:username]
      @password = options[:password]
      @uri = URI(options[:endpoint] || 'https://api-fcc4d.freeconferencecall.com/v2/api/')
      @timeout = options[:timeout].to_i
    end

    def sms
      @sms ||= FCC4D::SMS.new self
    end

    def push
      @push ||= FCC4D::Push.new self
    end

    def lookup
      @lookup ||= FCC4D::Lookup.new self
    end

    def countries
      @countries ||= FCC4D::Countries.new self
    end

    def get content_type, api_call_path
      api_call content_type, Net::HTTP::Get, api_call_path, nil
    end

    def post content_type, api_call_path, data
      api_call content_type, Net::HTTP::Post, api_call_path, data
    end

    def put content_type, api_call_path, data
      api_call content_type, Net::HTTP::Put, api_call_path, data
    end

    def patch content_type, api_call_path, data
      api_call content_type, Net::HTTP::Patch, api_call_path, data
    end

    private

    def api_call content_type, request_class, api_call_path, data
      path = File.join(@uri.to_s, api_call_path) 

      request = request_class.new(path, headers[content_type])
      if @username && @password
        request.basic_auth @username, @password
      end

      if data
        if content_type == :json
          request.body = data.to_json
        elsif content_type == :form
          request.form_data = data
        end
      end


      connection = Net::HTTP.new(@uri.hostname, @uri.port)
      connection.use_ssl = @uri.scheme == 'https'

      if @timeout > 0
        connection.read_timeout = @timeout
        connection.open_timeout = @timeout
      end

      response = connection.start do |http|
        http.request(request)
      end

      JSON::parse response.body
    end

    def headers
      @headers ||= {
        json: base_headers.merge('Content-Type' => 'application/json'),
        form: base_headers.merge('Content-Type' => 'application/x-www-form-urlencoded')
      }
    end

    def base_headers
      @base_headers ||= {
        'Accept' => 'application/json'
      }.merge(authorization_header)
    end

    def authorization_header
      if @auth_token
        {'Authorization' => "Bearer #@auth_token"}
      else
        {}
      end
    end

  end
end
