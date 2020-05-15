require 'memoist'
require 'faraday'
require 'better-faraday'

module Peatio
  module Ripple
    class Client
      Error = Class.new(StandardError)
      ConnectionError = Class.new(Error)

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
        @json_rpc_call_id = 0
      end

      def json_rpc(method, params = [])
        response = connection.post \
          '/',
          { jsonrpc: '2.0', id: rpc_call_id, method: method, params: params }.to_json,
          { 'Accept'       => 'application/json',
            'Content-Type' => 'application/json' }
        response.assert_2xx!
        response = JSON.parse(response.body)
        response.fetch('result').tap do |result|
          raise ResponseError.new(result['error_code'], result['error_message']) if result['status'] == 'error'
        end
        response.fetch('result')
      rescue Faraday::Error => e
        raise ConnectionError, e
      end

      private

      def rpc_call_id
        @json_rpc_call_id += 1
      end

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
