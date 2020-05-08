# frozen_string_literal: true

module Peatio::Electrum
  #
  # See the abstract class here:
  # https://github.com/openware/peatio-core/blob/master/lib/peatio/blockchain/abstract.rb
  #
  class Blockchain < Peatio::Blockchain::Abstract
    DEFAULT_FEATURES = {case_sensitive: true}.freeze

    # You could override default features by passing them to initializer.
    def initialize(custom_features = {})
      @features = DEFAULT_FEATURES.merge(custom_features)
    end

    # Merges given configuration parameters with defined during initialization
    # and returns the result.
    #
    # @param [Hash] settings parameters to use.
    #
    # @option settings [String] :server Public blockchain API endpoint.
    # @option settings [Array<Hash>] :currencies List of currency hashes
    #   with :id,:base_factor,:options(deprecated) keys.
    #   Custom keys could be added by defining them in Currency #options.
    #
    # @return [Hash] merged settings.
    #
    # @note Be careful with your blockchain state after configure.
    #       Clean everything what could be related to other blockchain configuration.
    #       E.g. client state.
    def configure(settings = {})
      @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))
    end

    # Fetches blockchain block by calling API and builds block object
    # from response payload.
    #
    # @param block_number [Integer] the block number.
    # @return [Peatio::Block] the block object.
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on blockchain API call.
    def fetch_block!(block_number)
      method_not_implemented
    end

    # Fetches current blockchain height by calling API and returns it as number.
    #
    # @return [Integer] the current blockchain height.
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on blockchain API call.
    def latest_block_number
      method_not_implemented
    end

    # Fetches address balance of specific currency.
    #
    # @note Optional. Don't override this method if your blockchain
    # doesn't provide functionality to get balance by address.
    #
    # @param address [String] the address for requesting balance.
    # @param currency_id [String] which currency balance we need to request.
    # @return [BigDecimal] the current address balance.
    # @raise [Peatio::Blockchain::ClientError,Peatio::Blockchain::UnavailableAddressBalanceError]
    # if error was raised on blockchain API call ClientError is raised.
    # if blockchain API call was successful but we can't detect balance
    # for address Error is raised.
    def load_balance_of_address!(address, currency_id)
      raise Peatio::Blockchain::UnavailableAddressBalanceError
    end
  end
end
