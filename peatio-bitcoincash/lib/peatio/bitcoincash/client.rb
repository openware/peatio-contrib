require 'memoist'
require 'faraday'
require 'better-faraday'

module Peatio
  module Bitcoincash
    class Client
      Error = Class.new(StandardError)
      class ConnectionError < Error; end

      class ResponseError < Error
        def initialize(code, msg)
          @code = code
          @msg = msg
        end

        def message
          "#{@msg} (#{@code})"
        end
      end

      extend Memoist

      def initialize(endpoint)
        @json_rpc_endpoint = URI.parse(endpoint)
      end

      def json_rpc(method, params = [])
        response = connection.post \
          '/',
          { jsonrpc: '1.0', method: method, params: params }.to_json,
          { 'Accept'       => 'application/json',
            'Content-Type' => 'application/json' }
        response.assert_2xx!
        response = JSON.parse(response.body)
        response['error'].tap { |e| raise ResponseError.new(e['code'], e['message']) if e }
        response.fetch('result')
      rescue => e
        if e.is_a?(Error)
          raise e
        elsif e.is_a?(Faraday::Error)
          raise ConnectionError, e
        else
          raise Error, e
        end
      end

      private

      def connection
        @connection ||= Faraday.new(@json_rpc_endpoint) do |f|
          f.adapter :net_http_persistent, pool_size: 5
        end.tap do |connection|
          unless @json_rpc_endpoint.user.blank?
            connection.basic_auth(@json_rpc_endpoint.user,
                                  @json_rpc_endpoint.password)
          end
        end
      end
    end
  end
end
