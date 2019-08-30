# frozen_string_literal: true

module Peatio
  module Telos
    class Wallet < Peatio::Wallet::Abstract
      PRECISION = 4

      ADDRESS_LENGTH = 12

      TOKEN_STANDARD = "eosio.token"

      class MissingTokenNameError < Peatio::Blockchain::Error; end

      def initialize(settings={})
        @settings = settings
      end

      def configure(settings={})
        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

        @wallet = @settings.fetch(:wallet) do
          raise Peatio::Wallet::MissingSettingError, :wallet
        end.slice(:uri, :address, :secret)

        @currency = @settings.fetch(:currency) do
          raise Peatio::Wallet::MissingSettingError, :wallet
        end.slice(:id, :base_factor, :options)
        raise MissingTokenNameError if @currency.dig(:options, :telos_token_name).blank?
      end

      def create_address!(options={})
        # For EOS and all others telosio.token deposits we use one EOS account which is defined like deposit wallet address in peatio.
        # In Peatio EOS plugin we will define owner of deposit by user unige identifier (UID)
        name = "#{@wallet.fetch(:address)}?memo=#{options.fetch(:uid)}"
        {address: name, secret: @wallet.fetch(:secret)}
      rescue Peatio::Telos::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def create_transaction!(transaction, _options={})
        tx = transaction
        amount = normalize_amount(tx.amount)
        address = normalize_address(@wallet.fetch(:address))
        # Pack main transaction info into hash
        packed_data = client.json_rpc("/v1/chain/abi_json_to_bin", Peatio::Telos::TransactionSerializer.to_pack_json(address: address,
                                     to_address: tx.to_address, amount: amount)).fetch("binargs")
        info = client.json_rpc("/v1/chain/get_info")
        # Get block info
        block = client.json_rpc("/v1/chain/get_block", "block_num_or_id" => info.fetch("last_irreversible_block_num"))
        ref_block_num = info.fetch("last_irreversible_block_num") & 0xFFFF
        # Get transaction expiration
        expiration = normalize_expiration(block.fetch("timestamp"))
        # Sign transaction before push
        signed = client.json_rpc("/v1/wallet/sign_transaction", Peatio::Telos::TransactionSerializer.to_sign_json(ref_block_num: ref_block_num,
                                block_prefix: block.fetch("ref_block_prefix"), expiration: expiration, address: address,
                                packed_data: packed_data, secret: @wallet.fetch(:secret), chain_id: info.fetch("chain_id")), 8900)
        txid = client.json_rpc("/v1/chain/push_transaction", Peatio::Telos::TransactionSerializer.to_push_json(address: address,
                              packed_data: packed_data, expiration: signed.fetch("expiration"), block_num: signed.fetch("ref_block_num"),
                              block_prefix: signed.fetch("ref_block_prefix"), signature: signed.fetch("signatures"))).fetch("transaction_id")
        tx.hash = txid
        tx
      rescue Peatio::Telos::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def load_balance!
        balance = client.json_rpc("/v1/chain/get_currency_balance",
                                  "account" => @wallet.fetch(:address), "code" => TOKEN_STANDARD)
                        .find {|b| b.split[1] == @currency.dig(:options, :telos_token_name) }
        balance.blank? ? 0 : normalize_balance(balance)
      rescue Peatio::Telos::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      private

      def normalize_address(address)
        address.gsub(/\?memo=\bID[A-Z0-9]{10}\Z/, "")
      end

      def normalize_amount(amount)
        "%.#{PRECISION}f" % amount + " #{@currency.dig(:options, :telos_token_name)}"
      end

      def normalize_balance(balance)
        balance.chomp(@currency.dig(:options, :telos_token_name)).to_d
      end

      def normalize_expiration(time)
        (Time.parse(time) + 3600).iso8601(6).split("+").first
      end

      def client
        uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
        @client ||= Client.new(uri)
      end
    end
  end
end
