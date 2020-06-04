module Peatio
  module Bitgo
    class Wallet < Peatio::Wallet::Abstract
      TIME_DIFFERENCE_IN_MINUTES = 10

      def initialize(settings = {})
        @settings = settings
      end

      def configure(settings = {})
        # Clean client state during configure.
        @client = nil

        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

        @wallet = @settings.fetch(:wallet) do
          raise Peatio::Wallet::MissingSettingError, :wallet
        end.slice(:uri, :address, :secret, :access_token, :wallet_id, :testnet)

         @currency = @settings.fetch(:currency) do
          raise Peatio::Wallet::MissingSettingError, :currency
         end.slice(:id, :base_factor, :code, :options)
      end

      def create_address!(options = {})
        currency = erc20_currency_id
        options.deep_symbolize_keys!

        if options.dig(:pa_details, :address_id).present? &&
           options.dig(:pa_details, :updated_at).present? &&
           time_difference_in_minutes(options.dig(:pa_details, :updated_at)) >= TIME_DIFFERENCE_IN_MINUTES

          response = client.rest_api(:get, "#{currency}/wallet/#{wallet_id}/address/#{options.dig(:pa_details, :address_id)}")
          { address: response['address'], secret: bitgo_wallet_passphrase }
        elsif options.dig(:pa_details, :address_id).blank?
          response = client.rest_api(:post, "#{currency}/wallet/#{wallet_id}/address")
          { address: response['address'], secret: bitgo_wallet_passphrase, details: { address_id: response['id'] }}
        end
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def create_transaction!(transaction, options = {})
        currency_options = @currency.fetch(:options).slice(:gas_limit, :gas_price, :erc20_contract_address)

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

          txid = client.rest_api(:post, "#{currency_id}/wallet/#{wallet_id}/sendcoins", {
                                 address: transaction.to_address.to_s,
                                 amount: amount.to_s,
                                 walletPassphrase: bitgo_wallet_passphrase,
                                 memo: xlm_memo(transaction.to_address.to_s)
          }.compact).fetch('txid')

          transaction.hash = normalize_txid(txid)
          transaction
        end
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end


      def build_raw_transaction(transaction)
        client.rest_api(:post, "#{currency_id}/wallet/#{wallet_id}/tx/build", {
          recipients: [{
            address: transaction.to_address,
            amount: convert_to_base_unit(transaction.amount).to_s
          }]
        }.compact)
      end

      def create_eth_transaction(transaction, options = {})
        amount = convert_to_base_unit(transaction.amount)
        hop = true unless options.slice(:erc20_contract_address).present?

        txid = client.rest_api(:post, "#{currency_id}/wallet/#{wallet_id}/sendcoins", {
          address: transaction.to_address.to_s,
          amount: amount.to_s,
          walletPassphrase: bitgo_wallet_passphrase,
          gas: options.fetch(:gas_limit).to_i,
          gasPrice: options.fetch(:gas_price).to_i,
          hop: hop
        }.compact).fetch('txid')

        transaction.hash = normalize_txid(txid)
        transaction
      end

      def load_balance!
        if @currency.fetch(:options).slice(:erc20_contract_address).present?
          load_erc20_balance!
        else
          response = client.rest_api(:get, "#{currency_id}/wallet/#{wallet_id}")
          convert_from_base_unit(response.fetch('balanceString'))
        end
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def load_erc20_balance!
        response = client.rest_api(:get, "#{erc20_currency_id}/wallet/#{wallet_id}?allTokens=true")
        convert_from_base_unit(response.dig('tokens', currency_id, 'balanceString'))
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def trigger_webhook_event(event)
        currency_id = @wallet.fetch(:testnet).present? ? 't' + @currency.fetch(:id) : @currency.fetch(:id)
        return unless currency_id == event['coin'] && @wallet.fetch(:wallet_id) == event['wallet']

        if event['type'] == 'transfer'
          transactions = fetch_transfer!(event['transfer'])
          return { transfers: transactions }
        elsif event['type'] == 'address_confirmation'
          address_id = fetch_address_id(event['address'])
          return { address_id: address_id}
        end
      end

      def register_webhooks!(url)
        transfer_webhook(url)
        address_confirmation_webhook(url)
      end

      def fetch_address_id(address)
        currency = erc20_currency_id
        client.rest_api(:get, "#{currency}/wallet/#{wallet_id}/address/#{address}")
              .fetch('id')
      rescue Bitgo::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def fetch_transfer!(id)
        # TODO: Add Rspecs for this one
        response = client.rest_api(:get, "#{currency_id}/wallet/#{wallet_id}/transfer/#{id}")
        parse_entries(response['entries']).map do |entry|
          to_address =  if response.dig('coinSpecific', 'memo').present?
                          memo = response.dig('coinSpecific', 'memo')
                          memo_type = memo.kind_of?(Array) ? memo.first  : memo
                          build_address(entry['address'], memo_type)
                        else
                          entry['address']
                        end
          state = define_transaction_state(response['state'])

          transaction = Peatio::Transaction.new(
            currency_id: @currency.fetch(:id),
            amount: convert_from_base_unit(entry['valueString']),
            hash: normalize_txid(response['txid']),
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
        client.rest_api(:post, "#{currency_id}/wallet/#{wallet_id}/webhooks", {
          type: 'transfer',
          allToken: true,
          url: url,
          label: "webhook for #{url}",
          listenToFailureStates: false
        })
      end

      def address_confirmation_webhook(url)
        client.rest_api(:post, "#{currency_id}/wallet/#{wallet_id}/webhooks", {
          type: 'address_confirmation',
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
        uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
        access_token = @wallet.fetch(:access_token) { raise Peatio::Wallet::MissingSettingError, :access_token }

        currency_code_prefix = @wallet.fetch(:testnet) ? 't' : ''
        uri = uri.gsub(/\/+\z/, '') + '/' + currency_code_prefix
        @client ||= Client.new(uri, access_token)
      end

      def build_address(address, memo)
        "#{address}?memoId=#{memo['value']}"
      end

      # All these functions will have to be done with the coin set to eth or teth
      # since that is the actual coin type being used.
      def erc20_currency_id
        return 'eth' if @currency.fetch(:options).slice(:erc20_contract_address).present?

        currency_id
      end

      def xlm_memo(address)
        if @currency.fetch(:id) == 'xlm'
            {
              type: "id",
              value: "#{memo_id_from(address)}"
            }
        end
      end

      def memo_id_from(address)
        memo_id = address.partition('memoId=').last
        memo_id = 0 if memo_id.empty?

        memo_id
      end

      def currency_id
        @currency.fetch(:id) { raise Peatio::Wallet::MissingSettingError, :id }
      end

      def bitgo_wallet_passphrase
        @wallet.fetch(:secret)
      end

      def wallet_id
        @wallet.fetch(:wallet_id)
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

      def time_difference_in_minutes(updated_at)
        (Time.now - updated_at)/60
      end

      def define_transaction_state(state)
        case state
        when 'unconfirmed'
          'pending'
        when 'confirmed'
          'success'
        when 'failed','rejected'
          'failed'
        end
      end
    end
  end
end
