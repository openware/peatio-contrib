module Peatio
  module Ripple
    class Wallet < Peatio::Wallet::Abstract

      Error = Class.new(StandardError)

      def initialize(settings = {})
        @settings = settings
      end

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

      def create_address!(_setting)
        {
          address: "#{@wallet[:address]}?dt=#{SecureRandom.random_number(10**6)}",
          secret: @wallet[:secret]
        }
      end

      def create_raw_address(options = {})
        secret = options.fetch(:secret) { PasswordGenerator.generate(64) }
        result = client.json_rpc(:wallet_propose, [{ passphrase: secret }])

        result.slice('key_type', 'master_seed', 'master_seed_hex',
                      'master_key', 'public_key', 'public_key_hex')
              .merge(address: normalize_address(result.fetch('account_id')), secret: secret)
              .symbolize_keys
      end

      def create_transaction!(transaction, options = {})
        tx_blob = sign_transaction(transaction, options)
        client.json_rpc(:submit, [tx_blob]).yield_self do |result|
          error_message = {
            message: result.fetch('engine_result_message'),
            status: result.fetch('engine_result')
          }

          # TODO: It returns provision results. Transaction may fail or success
          # than change status to opposite one before ledger is final.
          # Need to set special status and recheck this transaction status
          if result['engine_result'].to_s == 'tesSUCCESS' && result['status'].to_s == 'success'
            transaction.hash = result.fetch('tx_json').fetch('hash')
          else
            raise Error, "XRP withdrawal from #{@wallet.fetch(:address)} to #{transaction.to_address} failed. Message: #{error_message}."
          end
          transaction
        end
      end

      def sign_transaction(transaction, options = {})
        account_address = normalize_address(@wallet[:address])
        destination_address = normalize_address(transaction.to_address)
        destination_tag = destination_tag_from(transaction.to_address)
        fee = calculate_current_fee

        amount = convert_to_base_unit(transaction.amount)

        # Subtract fees from initial deposit amount in case of deposit collection
        amount -= fee if options.dig(:subtract_fee)
        transaction.amount = convert_from_base_unit(amount) unless transaction.amount == amount

          params = [{
          secret: @wallet.fetch(:secret),
          tx_json: {
            Account:            account_address,
            Amount:             amount.to_s,
            Fee:                fee.to_s,
            Destination:        destination_address,
            DestinationTag:     destination_tag,
            TransactionType:    'Payment',
            LastLedgerSequence: latest_block_number + 4
            }
          }]

        client.json_rpc(:sign, params).yield_self do |result|
          if result['status'].to_s == 'success'
            { tx_blob: result['tx_blob'] }
          else
            raise Error, "XRP sign transaction from #{account_address} to #{destination_address} failed: #{result}."
          end
        end
      end

      # Returns fee in drops that is enough to process transaction in current ledger
      def calculate_current_fee
        client.json_rpc(:fee, {}).yield_self do |result|
          result.dig('drops', 'open_ledger_fee').to_i
        end
      end

      def latest_block_number
        client.json_rpc(:ledger, [{ ledger_index: 'validated' }]).fetch('ledger_index')
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def load_balance!
        client.json_rpc(:account_info,
                        [account: normalize_address(@wallet.fetch(:address)), ledger_index: 'validated', strict: true])
                        .fetch('account_data')
                        .fetch('Balance')
                        .to_d
                        .yield_self { |amount| convert_from_base_unit(amount) }

      rescue Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      private

      def destination_tag_from(address)
        address =~ /\?dt=(\d*)\Z/
        $1.to_i
      end

      def normalize_address(address)
        address.gsub(/\?dt=\d*\Z/, '')
      end

      def convert_from_base_unit(value)
        value.to_d / @currency.fetch(:base_factor).to_d
      end

      def convert_to_base_unit(value)
        x = value.to_d * @currency.fetch(:base_factor)
        unless (x % 1).zero?
          raise Peatio::Ripple::Wallet::Error,
              "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " \
              "#{value.to_d} - #{x.to_d} must be equal to zero."
        end
        x.to_i
      end

      def client
        uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
        @client ||= Client.new(uri)
      end
    end
  end
end
