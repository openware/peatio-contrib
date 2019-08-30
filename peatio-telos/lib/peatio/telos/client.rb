# frozen_string_literal: true

require "memoist"
require "faraday"
require "better-faraday"

module Peatio
  module Telos
    class Client
      Error = Class.new(StandardError)
      class ConnectionError < Error; end

      class ResponseError < StandardError
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
        @rpc_endpoint = URI.parse(endpoint)
      end

      def json_rpc(path, params=nil, port=nil)
        # We need to communicate with ktelosd to sign transaction,
        # ktelosd is running on non default telos port which is 8900
        # and passed to json_rpc function when we sign transaction
        rpc = URI.parse(@rpc_endpoint.to_s)
        rpc.port = (port.present? ? port : @rpc_endpoint.port)
        response = connection(rpc).post do |req|
          req.url path

          # To communicate with ktelosd to sign transaction we need to pass Host param with ktelosd port
          req.headers["Host"] = "0.0.0.0:#{port}" if port.present?
          req.headers["Content-Type"] = "application/json"
          req.body = params.to_json if params.present?
        end
        response.assert_success!
        response = JSON.parse(response.body)
        return response if response.is_a?(Array) # get balance call return an array

        response["error"].tap {|error| raise ResponseError.new(error["code"], error["message"]) if error }
        response
      end

      private

      def connection(rpc)
        Faraday.new(rpc)
      end
      memoize :connection
    end
  end
end
