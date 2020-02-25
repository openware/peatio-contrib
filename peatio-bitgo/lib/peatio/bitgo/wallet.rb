module Peatio
  module Bitgo
    class Wallet < Peatio::Wallet::Abstract

      def initialize(settings = {})
        @settings = settings
      end

      def configure(settings = {})
        # Clean client state during configure.
        @client = nil

        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

        @wallet = @settings.fetch(:wallet) do
          raise Peatio::Wallet::MissingSettingError, :wallet
        end.slice(:uri, :address, :secret, :bitgo_access_token, :bitgo_wallet_id, :bitgo_test_net)

         @currency = @settings.fetch(:currency) do
          raise Peatio::Wallet::MissingSettingError, :currency
         end.slice(:id, :base_factor, :code, :options)
      end

      def create_address!(options = {})
        if options[:address_id].present?
          response = client.rest_api(:get, "/wallet/#{bitgo_wallet_id}/address/#{options[:address_id]}")
          { address: response['address'], secret: bitgo_wallet_passphrase }
        else
          response = client.rest_api(:post, "/wallet/#{bitgo_wallet_id}/address")
          { address: response['address'], secret: bitgo_wallet_passphrase, details: { address_id: response['id'] }}
        end
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def create_transaction!(transaction, options = {})
        currency_options = @currency.fetch(:options).slice(:gas_limit, :gas_price)

        if currency_options[:gas_limit].present? && currency_options[:gas_price].present?
          options.merge!(currency_options)
          create_eth_transaction(transaction, options)
        else
          amount = convert_to_base_unit(transaction.amount)

          if options[:subtract_fee].to_s == 'true'
            fee = build_raw_transaction(transaction)
            baseFeeInfo = fee.dig('feeInfo','fee')
            fee = baseFeeInfo.present? ? baseFeeInfo : fee.dig('txInfo','Fee')
            amount -= fee.to_i
          end

          txid = client.rest_api(:post, "/wallet/#{bitgo_wallet_id}/sendcoins", {
                                 address: transaction.to_address.to_s,
                                 amount: amount.to_s,
                                 walletPassphrase: bitgo_wallet_passphrase
          }.compact).fetch('txid')

          transaction.hash = normalize_txid(txid)
          transaction
        end
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end


      def build_raw_transaction(transaction)
        client.rest_api(:post, "/wallet/#{bitgo_wallet_id}/tx/build", {
          recipients: [{
            address: transaction.to_address,
            amount: convert_to_base_unit(transaction.amount).to_s
          }]
        }.compact)
      end

      def create_eth_transaction(transaction, options = {})
        amount = convert_to_base_unit(transaction.amount)
        amount -= options.fetch(:gas_limit).to_i * options.fetch(:gas_price).to_i if options.dig(:subtract_fee)

        txid = client.rest_api(:post, "/wallet/#{bitgo_wallet_id}/sendcoins", {
          address: transaction.to_address.to_s,
          amount: amount.to_s,
          walletPassphrase: bitgo_wallet_passphrase,
          gas: options.fetch(:gas_limit).to_i,
          gasPrice: options.fetch(:gas_price).to_i
        }.compact).fetch('txid')

        transaction.hash = normalize_txid(txid)
        transaction
      end

      def load_balance!
        response = client.rest_api(:get, "/wallet/#{bitgo_wallet_id}")
        convert_from_base_unit(response.fetch('balanceString'))
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def trigger_webhook_event(event)
        currency_id = @wallet.fetch(:bitgo_test_net).present? ? 't' + @currency.fetch(:id) : @currency.fetch(:id)
        return unless currency_id == event['coin'] && @wallet.fetch(:bitgo_wallet_id) == event['wallet']

        if event['type'] == 'transfer'
          transactions = fetch_transfer!(event['transfer'])
          return { transfers: transactions }
        elsif event['address_confirmation']
          # TODO Add Address confirmation
        end
      end

      def register_webhooks!(url)
        transfer_webhook(url)
        address_confirmation_webhook(url)
      end

      def fetch_transfer!(id)
        # TODO: Add Rspecs for this one
        response = client.rest_api(:get, "/wallet/#{bitgo_wallet_id}/transfer/#{id}")
        parse_entries(response['entries']).map do |entry|
          to_address =  if response.dig('coinSpecific', 'memo').present?
                          build_address(response.dig('coinSpecific', 'memo').first)
                        else
                          entry['address']
                        end
          state = if response['state'] == 'unconfrimed'
                    'pending'
                  elsif response['state'] == 'confirmed'
                    'success'
                  end

          transaction = Peatio::Transaction.new(
            currency_id: @currency.fetch(:id),
            amount: convert_from_base_unit(response['valueString']),
            hash: response['txid'],
            to_address: to_address,
            block_number: response['height'],
            # TODO: Add sendmany support
            txout: 0,
            status: state
          )
          transaction if transaction.valid?
        end.compact
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def transfer_webhook(url)
        client.rest_api(:post, "/wallet/#{bitgo_wallet_id}/webhooks", {
          type: 'transfer',
          allToken: true,
          url: url,
          label: "webhook for #{url}",
          listenToFailureStates: false
        })
      end

      def address_confirmation_webhook(url)
        client.rest_api(:post, "/wallet/#{bitgo_wallet_id}/webhooks", {
          type: 'address_confirmation_webhook',
          allToken: true,
          url: url,
          label: "webhook for #{url}",
          listenToFailureStates: false
        })
      end

      def parse_entries(entries)
        entries.map do |e|
          e if e["valueString"].to_i.positive?
        end.compact
      end

      private

      def client
        currency_id = @currency.fetch(:id) { raise Peatio::Wallet::MissingSettingError, :id }
        uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
        access_token = @wallet.fetch(:bitgo_access_token) { raise Peatio::Wallet::MissingSettingError, :bitgo_access_token }

        currency_code_prefix = @wallet.fetch(:bitgo_test_net) ? 't' : ''
        uri = uri.gsub(/\/+\z/, '') + '/' + currency_code_prefix + currency_id
        @client ||= Client.new(uri, access_token)
      end

      def build_address(memo)
        "#{memo['address']}?memoId=#{memo['value']}"
      end

      def bitgo_wallet_passphrase
        @wallet.fetch(:secret)
      end

      def bitgo_wallet_id
        @wallet.fetch(:bitgo_wallet_id)
      end

      def normalize_txid(txid)
        txid.downcase
      end

      def convert_from_base_unit(value)
        value.to_d / @currency.fetch(:base_factor)
      end

      def convert_to_base_unit(value)
        x = value.to_d * @currency.fetch(:base_factor)
        unless (x % 1).zero?
          raise Peatio::WalletClient::Error,
                "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " \
                "#{value.to_d} - #{x.to_d} must be equal to zero."
        end
        x.to_i
      end
    end
  end
end
