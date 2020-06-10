# frozen_string_literal: true

module Peatio::Electrum
  #
  # See the abstract class here:
  # https://github.com/openware/peatio-core/blob/master/lib/peatio/wallet/abstract.rb
  #
  class Wallet < Peatio::Wallet::Abstract
    attr_reader :client

    DEFAULT_FEATURES = { skip_deposit_collection: false }.freeze

    def initialize(custom_features = {})
      @features = DEFAULT_FEATURES.merge(custom_features).slice(*SUPPORTED_FEATURES)
      @settings = {}
    end

    # Merges given configuration parameters with defined during initialization
    # and returns the result.
    #
    # @param [Hash] settings configurations to use.
    # @option settings [Hash] :wallet Wallet settings for performing API calls.
    # With :address required key other settings could be customized
    # using Wallet#settings.
    # @option settings [Array<Hash>] :currencies List of currency hashes
    #   with :id,:base_factor,:options(deprecated) keys.
    #   Custom keys could be added by defining them in Currency #options.
    #
    # @return [Hash] merged settings.
    #
    # @note Be careful with your wallet state after configure.
    #       Clean everything what could be related to other wallet configuration.
    #       E.g. client state.
    def configure(settings = {})
      @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

      @wallet = @settings.fetch(:wallet) do
        raise Peatio::Wallet::MissingSettingError, :wallet
      end.slice(:uri, :address, :secret)

      @currency = @settings.fetch(:currency) do
        raise Peatio::Wallet::MissingSettingError, :currency
      end.slice(:id, :base_factor, :options)

      unless @settings[:wallet][:uri]
        raise Peatio::Wallet::MissingSettingError, 'Missing uri in wallet'
      end

      @client = Client.new(@settings[:wallet][:uri])
    end

    # Performs API call for address creation and returns it.
    #
    # @param [Hash] options
    # @options options [String] :uid User UID which requested address creation.
    #
    # @return [Hash] newly created blockchain address.
    #
    # @raise [Peatio::Wallet::ClientError] if error was raised
    #   on wallet API call.
    #
    # @example
    #   { address: :fake_address,
    #     secret:  :changeme,
    #     details: { uid: account.member.uid } }
    def create_address!(_options = {})
      {
        address: client.create_address
      }
    rescue Peatio::Electrum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    # Performs API call for creating transaction and returns updated transaction.
    #
    # @param [Peatio::Transaction] transaction transaction with defined
    # to_address, amount & currency_id.
    #
    # @param [Hash] options
    # @options options [String] :subtract_fee Defines if you need to subtract
    #   fee from amount defined in transaction.
    #   It means that you need to deduct fee from amount declared in
    #   transaction and send only remaining amount.
    #   If transaction amount is 1.0 and estimated fee
    #   for sending transaction is 0.01 you need to send 0.09
    #   so 1.0 (0.9 + 0.1) will be subtracted from wallet balance
    #
    # @options options [String] custon options for wallet client.
    #
    # @return [Peatio::Transaction] transaction with updated hash.
    #
    # @raise [Peatio::Wallet::ClientError] if error was raised
    #   on wallet API call.
    def create_transaction!(transaction, _options = {})
      tx = client.payto(transaction.to_address, transaction.amount, password: @settings[:wallet][:secret])['hex']
      txid = client.broadcast(tx)
      transaction.hash = txid
      transaction
    rescue Peatio::Electrum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    # Fetches address balance of specific currency.
    #
    # @note Optional. Don't override this method if your blockchain
    # doesn't provide functionality to get balance by address.
    #
    # @return [BigDecimal] the current address balance.
    #
    # @raise [Peatio::Wallet::ClientError]
    # if error was raised on wallet API call ClientError is raised.
    # if wallet API call was successful but we can't detect balance
    # for address Error is raised.
    def load_balance!
      client.get_balance
    rescue Peatio::Electrum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

  end
end
