# frozen_string_literal: true

module Peatio::Electrum
  class Client
    attr_reader :connection

    Error = Class.new(StandardError)
    ConfigurationError = Class.new(Error)

    class ResponseError < Error
      def initialize(code, msg)
        @code = code
        @msg = msg
      end

      def message
        "#{@msg} (#{@code})"
      end
    end

    def initialize(wallet_url)
      @connection = Faraday.new(url: wallet_url)
    end

    def new_id
      (Time.now.to_f * 1000).to_i
    end

    def call(method, params = [])
      body = {
        id: new_id,
        method: method,
        params: params
      }.to_json

      headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

      response = JSON.parse(connection.post('/', body, headers).body)
      error = response['error']
      raise ResponseError.new(error['code'], error['message']) unless error.nil?

      response['result']
    end

    def is_synchronized
      call('is_synchronized', [])
    end

    def get_local_height
      call('get_local_height', [])
    end

    def get_balance
      call('getbalance')['confirmed'].to_d
    end

    def get_address_balance(address)
      call('getaddressbalance', [address])
        .map { |k, v| [k, v.to_d] }.to_h
    end

    def create_address
      call('createnewaddress')
    end

    def list_unspent
      call('listunspent')
    end

    def get_tx_status(txid)
      call('get_tx_status', [txid])
    end

    def get_transaction(txid)
      call('gettransaction', [txid])
    end

    def history(year = nil, show_addresses = true, show_fiat = false, show_fees = true, from_height = nil, to_height = nil)
      JSON.parse(call('history', [year, show_addresses, show_fiat, show_fees, from_height, to_height]))
    end

    ## Default options:
    ## fee: nil
    ## from_addr: nil
    ## change_addr: nil
    ## nocheck: false
    ## unsigned: false
    ## rbf: nil
    ## password: nil
    ## locktime: nil
    def payto(destination, amount, opts = {})
      call('payto', {
        destination: destination,
        amount: amount
      }.merge(opts).compact)
    end

    def broadcast(tx)
      call('broadcast', [tx])
    end
  end
end
