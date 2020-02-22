require 'faraday'
require 'better-faraday'

module Peatio
  module Bitgo
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

      def initialize(endpoint)
        
      end
    end
  end
end

