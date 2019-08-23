# frozen_string_literal: true

module Peatio
  module Dash
    class Wallet < Peatio::Wallet::Abstract
      def initialize(settings={})
        @settings = settings
      end

      def configure(settings={})
        # Clean client state during configure.
        @client = nil

        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

        @wallet = @settings.fetch(:wallet) {
          raise Peatio::Wallet::MissingSettingError, :wallet
        }.slice(:uri, :address)

        @currency = @settings.fetch(:currency) {
          raise Peatio::Wallet::MissingSettingError, :currency
        }.slice(:id, :base_factor, :options)
      end

      def create_address!(_options={})
        {address: client.json_rpc(:getnewaddress)}
      rescue Dash::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def create_transaction!(transaction, options={})
        txid = client.json_rpc(:sendtoaddress,
                               [
                                 transaction.to_address,
                                 transaction.amount,
                                 "",
                                 "",
                                 options[:subtract_fee].to_s == "true" # subtract fee from transaction amount.
                               ])
        transaction.hash = txid
        transaction
      rescue Dash::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def load_balance!
        client.json_rpc(:getbalance).to_d
      rescue Dash::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      private

      def client
        uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
        @client ||= Client.new(uri)
      end
    end
  end
end
