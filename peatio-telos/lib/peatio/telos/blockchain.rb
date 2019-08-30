# frozen_string_literal: true

module Peatio
  module Telos
    class Blockchain < Peatio::Blockchain::Abstract
      DEFAULT_FEATURES = {case_sensitive: true, cash_addr_format: false}.freeze

      TOKEN_STANDARD = "eosio.token"

      class MissingTokenNameError < Peatio::Blockchain::Error; end
      class UndefinedCurrencyError < Peatio::Blockchain::Error; end

      def initialize(custom_features={})
        @features = DEFAULT_FEATURES.merge(custom_features).slice(*SUPPORTED_FEATURES)
        @settings = {}
      end

      def configure(settings={})
        # Clean client state during configure.
        @client = nil

        supported_settings = settings.slice(*SUPPORTED_SETTINGS)
        supported_settings[:currencies]&.each do |c|
          raise MissingTokenNameError, c[:id] if c.dig(:options, :telos_token_name).blank?
        end
        @settings.merge!(supported_settings)
      end

      def fetch_block!(block_number)
        client.json_rpc("/v1/chain/get_block", "block_num_or_id" => block_number)
              .fetch("transactions").each_with_object([]) do |tx, txs_array|
          txs = build_transaction(tx).map do |ntx|
            Peatio::Transaction.new(ntx.merge(block_number: block_number))
          end
          txs_array.append(*txs)
        end.yield_self {|txs_array| Peatio::Block.new(block_number, txs_array) }
      rescue Peatio::Telos::Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def load_balance_of_address!(address, currency_id)
        currency = settings_fetch(:currencies).find {|c| c[:id] == currency_id }
        raise UndefinedCurrencyError unless currency

        balance = client.json_rpc("/v1/chain/get_currency_balance",
                                  "account" => address, "code" => TOKEN_STANDARD)
                        .find {|b| b.split[1] == currency.dig(:options, :telos_token_name) }

        # EOS return array with balances for all telosio.token currencies
        balance.blank? ? 0 : normalize_balance(balance, currency)
      rescue Peatio::Telos::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def latest_block_number
        client.json_rpc("/v1/chain/get_info").fetch("head_block_num")
      rescue Peatio::Telos::Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      private

      def build_transaction(tx)
        return [] if tx["trx"]["id"].blank? # check for deferred transaction

        tx.dig("trx", "transaction", "actions")
          .each_with_object([]).with_index do |(entry, formatted_txs), i|
          next unless entry["name"] == "transfer" && !entry["data"]["to"].empty?

          amount, token_name = entry["data"]["quantity"].split
          next if amount.to_d < 0

          currencies = settings_fetch(:currencies).select {|c| c.dig(:options, :telos_token_name) == token_name }
          status = tx["status"] == "executed" ? "success" : "failed"
          address = "#{entry['data']['to']}?memo=#{get_memo(entry['data']['memo'])}"

          # Build transaction for each currency belonging to blockchain.

          currencies.pluck(:id).each do |currency_id|
            formatted_txs << {hash: tx["trx"]["id"],
                               txout: i,
                               to_address: address,
                               amount: amount.to_d,
                               status: status,
                               currency_id: currency_id}
          end
        end
      end

      def normalize_balance(balance, currency)
        balance.chomp(currency.dig(:options, :telos_token_name)).to_d
      end

      def get_memo(memo)
        memo.match(/\bID[A-Z0-9]{10}\z/) ? memo : ""
      end

      def client
        @client ||= Peatio::Telos::Client.new(settings_fetch(:server))
      end

      def settings_fetch(key)
        @settings.fetch(key) { raise Peatio::Blockchain::MissingSettingError, key.to_s }
      end
    end
  end
end
