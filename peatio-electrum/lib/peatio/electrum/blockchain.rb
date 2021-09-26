# frozen_string_literal: true

module Peatio::Electrum
  #
  # See the abstract class here:
  # https://github.com/openware/peatio-core/blob/master/lib/peatio/blockchain/abstract.rb
  #
  class Blockchain < Peatio::Blockchain::Abstract
    attr_reader :client
    DEFAULT_FEATURES = { case_sensitive: true }.freeze

    # You could override default features by passing them to initializer.
    def initialize(custom_features = {})
      @features = DEFAULT_FEATURES.merge(custom_features)
      @settings = {}
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
      @client = Client.new(@settings[:server])
      @currencies_ids = @settings[:currencies].pluck(:id)
    end

    # Fetches blockchain block by calling API and builds block object
    # from response payload.
    #
    # @param block_number [Integer] the block number.
    # @return [Peatio::Block] the block object.
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on blockchain API call.
    def fetch_block!(block_number)
      block = fetch_multi_blocks!(block_number, block_number + 1).first
      return Peatio::Block.new(block_number, []) if block.nil?

      block
    end

    # Fetches multiple blocks from the blockchain and builds an aggregated object
    # from response payload.
    #
    # @param block_number_from [Integer] the block number to start from
    # @param block_number_to [Integer] the endding block number (included)
    # @return [Peatio::Block] the block object.
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on blockchain API call.
    def fetch_multi_blocks!(block_number_from, block_number_to)
      unless client.is_synchronized
        raise Peatio::Blockchain::ClientError, 'Electrum is synchronizing'
      end

      txs = []
      blocks = []
      current_height = block_number_from

      client.history(nil, true, false, true, block_number_from, block_number_to)['transactions'].each do |tx|
        if tx['height'] != current_height
          blocks << Peatio::Block.new(current_height, txs) unless txs.empty?
          txs = []
          current_height = tx['height']
        end
        fee = tx['fee']

        (tx['outputs'] || []).each_with_index do |out, i|
          @currencies_ids.each do |currency_id|
            txs << Peatio::Transaction.new(
              hash: tx['txid'],
              txout: i,
              to_address: out['address'],
              amount: out['value'].to_d,
              status: 'success',
              block_number: tx['height'],
              currency_id: currency_id,
              fee_currency_id: currency_id,
              fee: fee
            )
          end
        end
      end
      blocks << Peatio::Block.new(current_height, txs) unless txs.empty?
      blocks
    end

    # Fetches current blockchain height by calling API and returns it as number.
    #
    # @return [Integer] the current blockchain height.
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on blockchain API call.
    def latest_block_number
      client.get_local_height
    rescue Client::Error => e
      raise Peatio::Blockchain::ClientError, e
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
    def load_balance_of_address!(address, _currency_id)
      client.get_address_balance(address)['confirmed']
    end
  end
end
