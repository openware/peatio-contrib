
module Peatio
  module Ripple
    class Blockchain < Peatio::Blockchain::Abstract

      # Flow:
      # get block_number from params
      # fetch transactions from this block
      # build transactions from prev step

      UndefinedCurrencyError = Class.new(StandardError)

      DEFAULT_FEATURES = { case_sensitive: true, cash_addr_format: false }.freeze

      def initialize(custom_features = {})
        @features = DEFAULT_FEATURES.merge(custom_features).slice(*SUPPORTED_FEATURES)
        @settings = {}
      end

      def configure(settings = {})
        # Clean client state during configure.
        @client = nil
        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))
      end

      def fetch_block!(ledger_index)
        ledger = client.json_rpc(:ledger,
                                     [
                                       {
                                         ledger_index: ledger_index || 'validated',
                                         transactions: true,
                                         expand: true
                                       }
                                     ]).dig('ledger')

        return if ledger.blank?
        ledger.fetch('transactions').each_with_object([]) do |tx, txs_array|
          next unless valid_transaction?(tx)

          txs = build_transaction(tx).map do |ntx|
            Peatio::Transaction.new(ntx.merge(block_number: ledger_index))
          end
          txs_array.append(*txs)
        end.yield_self { |txs_array| Peatio::Block.new(ledger_index, txs_array) }
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def latest_block_number
        client.json_rpc(:ledger, [{ ledger_index: 'validated' }]).fetch('ledger_index')
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def load_balance_of_address!(address, currency_id)
        currency = settings[:currencies].find { |c| c[:id] == currency_id.to_s }
        raise UndefinedCurrencyError unless currency

        client.json_rpc(:account_info,
                        [account: normalize_address(address), ledger_index: 'validated', strict: true])
                        .fetch('account_data')
                        .fetch('Balance')
                        .to_d
                        .yield_self { |amount| convert_from_base_unit(amount, currency) }

      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      private

      def build_transaction(tx_hash)
        destination_tag = tx_hash['DestinationTag'] || destination_tag_from(tx_hash['Destination'])
        address = "#{to_address(tx_hash)}?dt=#{destination_tag}"

        settings_fetch(:currencies).each_with_object([]) do |currency, formatted_txs|
          formatted_txs << { hash: tx_hash['hash'],
                             txout: tx_hash.dig('metaData','TransactionIndex'),
                             to_address: address,
                             status: check_status(tx_hash),
                             currency_id: currency[:id],
                             amount: convert_from_base_unit(tx_hash.dig('metaData', 'delivered_amount'), currency) }
        end
      end

      def settings_fetch(key)
        @settings.fetch(key) { raise Peatio::Blockchain::MissingSettingError, key.to_s }
      end

      def check_status(tx_hash)
        tx_hash.dig('metaData', 'TransactionResult') == 'tesSUCCESS' ? 'success' : 'failed'
      end

      def valid_transaction?(tx)
        inspect_address!(tx['Account'])[:is_valid] &&
          tx['TransactionType'].to_s == 'Payment' &&
          String === tx.dig('metaData', 'delivered_amount')
      end

      def inspect_address!(address)
        {
          address:  normalize_address(address),
          is_valid: valid_address?(normalize_address(address))
        }
      end

      def normalize_address(address)
        address.gsub(/\?dt=\d*\Z/, '')
      end

      def valid_address?(address)
        /\Ar[0-9a-zA-Z]{24,34}(:?\?dt=[1-9]\d*)?\z/.match?(address)
      end

      def destination_tag_from(address)
        address =~ /\?dt=(\d*)\Z/
        $1.to_i
      end

      def to_address(tx)
        normalize_address(tx['Destination'])
      end

      def convert_from_base_unit(value, currency)
        value.to_d / currency.fetch(:base_factor).to_d
      end

      def client
        @client ||= Client.new(settings_fetch(:server))
      end
    end
  end
end
