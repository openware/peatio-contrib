# frozen_string_literal: true

module Peatio::Electrum
  #
  # See the abstract class here:
  # https://github.com/openware/peatio-core/blob/master/lib/peatio/wallet/abstract.rb
  #
  class Wallet < Peatio::Wallet::Abstract

    def initialize(settings = {})
      @settings = settings
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
      # Clean client state during configure.
      @client = nil
      @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

      @wallet = @settings.fetch(:wallet) do
        raise Peatio::Wallet::MissingSettingError, :wallet
      end.slice(:uri, :address, :secret)

      @currency = @settings.fetch(:currency) do
        raise Peatio::Wallet::MissingSettingError, :currency
      end.slice(:id, :base_factor, :options)
    end

    # Performs API call for address creation and returns it.
    #
    # @param [Hash] options
    # @options options [String] :uid User UID which requested address creation.
    #
    # @return [Hash] newly created blockchain address.
    #
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on wallet API call.
    #
    # @example
    #   { address: :fake_address,
    #     secret:  :changeme,
    #     details: { uid: account.member.uid } }
    def create_address!(options = {})
      method_not_implemented
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
    # @raise [Peatio::Blockchain::ClientError] if error was raised
    #   on wallet API call.
    def create_transaction!(transaction, options = {})
      method_not_implemented
    end

    # Fetches address balance of specific currency.
    #
    # @note Optional. Don't override this method if your blockchain
    # doesn't provide functionality to get balance by address.
    #
    # @return [BigDecimal] the current address balance.
    #
    # @raise [Peatio::Blockchain::ClientError,Peatio::Blockchain::UnavailableAddressBalanceError]
    # if error was raised on wallet API call ClientError is raised.
    # if wallet API call was successful but we can't detect balance
    # for address Error is raised.
    def load_balance!
      raise Peatio::Wallet::UnavailableAddressBalanceError
    end

    # Performs API call(s) for preparing for deposit collection.
    # E.g deposits ETH for collecting ERC20 tokens in case of Ethereum blockchain.
    #
    # @note Optional. Override this method only if you need additional step
    # before deposit collection.
    #
    # @param [Peatio::Transaction] deposit_transaction transaction which
    # describes received deposit.
    #
    # @param [Array<Peatio::Transaction>] spread_transactions result of deposit
    # spread between wallets.
    #
    # @return [Array<Peatio::Transaction>] transaction created for
    # deposit collection preparing.
    # By default return empty [Array]
    def prepare_deposit_collection!(deposit_transaction, spread_transactions, deposit_currency)
      # This method is mostly used for coins which needs additional fees
      # to be deposited before deposit collection.
      []
    end

  end
end
