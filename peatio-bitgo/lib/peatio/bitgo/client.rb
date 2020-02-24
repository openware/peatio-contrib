require 'faraday'
require 'better-faraday'

module Peatio
  module Bitgo
    class Client
      Error = Class.new(StandardError)
      class ConnectionError < Error; end

      class ResponseError < Error
        def initialize(msg)
          super "#{msg}"
        end
      end

      def initialize(endpoint, access_token)
        @endpoint = URI.parse(endpoint)
        @access_token = access_token
      end

      def rest_api(verb, path, data = nil)
        args = [@endpoint.to_s + path]

        if data
          if %i[ post put patch ].include?(verb)
            args << data.compact.to_json
            args << { 'Content-Type' => 'application/json' }
          else
            args << data.compact
            args << {}
          end
        else
          args << nil
          args << {}
        end

        args.last['Accept']        = 'application/json'
        args.last['Authorization'] = 'Bearer ' + @access_token

        response = Faraday.send(verb, *args)
        response.assert_success!
        response = JSON.parse(response.body)
        response['error'].tap { |error| raise ResponseError.new(error) if error }
        response
      rescue Faraday::Error => e
        raise ConnectionError, e
      rescue StandardError => e
        raise Error, e
      end
    end
  end
end
