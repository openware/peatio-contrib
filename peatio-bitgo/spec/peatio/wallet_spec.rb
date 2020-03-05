RSpec.describe Peatio::Bitgo::Wallet do
  let(:wallet) { Peatio::Bitgo::Wallet.new }

  def request_headers(wallet)
    { 'Accept':        'application/json',
      'Authorization': 'Bearer ' + wallet[:access_token] }
  end

  let(:uri) { 'http://127.0.0.1:3080/api/v2' }

  let(:settings) do
    {
      wallet: {
        address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf',
        uri: uri,
        secret: 'changeme',
        access_token: 'v2x0b53e612518e5ea625eb3c24175438b37f56bc1f82e9c9ba3b038c91b0c72e67',
        wallet_id: '5a7d9f52ba1923b107b80baabe0c3574',
        testnet: true
      },
      currency: {
        id: 'btc',
        base_factor: 100_000_000,
        code: 'btc',
        options: {}
      }
    }
  end

  context :configure do
    let(:settings) { { wallet: {}, currency: {} }}

    it 'requires wallet' do
      expect{ wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect{ wallet.configure(settings) }.to_not raise_error
    end

    it 'requires currency' do
      expect{ wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect{ wallet.configure(settings) }.to_not raise_error
    end

    it 'sets settings attribute' do
      wallet.configure(settings)
      expect(wallet.settings).to eq(settings.slice(*Peatio::Bitgo::Wallet::SUPPORTED_SETTINGS))
    end
  end

  context :create_address! do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    before do
      wallet.configure(settings)
    end

    context 'address_id option for wallet creating is not provided' do
      before do
        stub_request(:post, uri + request_path)
        .with(body: {}, headers: request_headers(settings[:wallet]))
        .to_return(status: 200, body: response_body)
      end

      let(:response_body) {
        { address: "2MySruptM4SgZF49KSc3x5KyxAW61ghyvtc", secret: settings[:wallet][:secret],
          id: 'd9c359f727a22320b214afa9184f3'
        }.to_json
      }

      let(:request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/address' }

      it 'requests bitgo client and create address' do
        result = wallet.create_address!(uid: 'UID123')
        expect(result.symbolize_keys).to eq(address: '2MySruptM4SgZF49KSc3x5KyxAW61ghyvtc', secret: 'changeme',
          details: { :address_id => 'd9c359f727a22320b214afa9184f3' })
        end
      end

      context 'address_id option is provided' do
        before do
          stub_request(:get, uri + request_path)
          .with(body: {}, headers: request_headers(settings[:wallet]))
          .to_return(status: 200, body: response_body)
        end

        let(:response_body) {
          { address: "2MySruptM4SgZF49KSc3x5KyxAW61ghyvtc", secret: settings[:wallet][:secret],
            id: 'd9c359f727a22320b214afa9184f3'
          }.to_json
        }

        let(:request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/address/' + JSON.parse(response_body)["id"] }

        it 'requests bitgo client and create address' do
          result = wallet.create_address!(uid: 'UID123', pa_details: { address_id: 'd9c359f727a22320b214afa9184f3' })
          expect(result.symbolize_keys).to eq(address: '2MySruptM4SgZF49KSc3x5KyxAW61ghyvtc', secret: "changeme")
        end
      end
   end

  context :load_balance! do
      around do |example|
        WebMock.disable_net_connect!
        example.run
        WebMock.allow_net_connect!
      end

      before do
        wallet.configure(settings)
      end

      before do
        stub_request(:get, uri + request_path)
        .with(body: {}, headers: request_headers(settings[:wallet]))
        .to_return(status: 200, body: response_body)
      end

      let(:response_body) {
        {
          "allowBackupKeySigning": true,
          "approvalsRequired": 1,
          "balanceString": "500000000",
          "balance": 500000000,
          "coin": "tbtc",
          "coinSpecific": {
            "creationFailure": [],
            "pendingChainInitialization": true,
            "rootAddress": "GCTTCPH4IIDK7P72FFAEJ3ZFN6WDHJH6GGMRPHPM56ZWGIQ7B3XTIJAM",
            "stellarUsername": "foo_bar@baz.com",
            "homeDomain": "bitgo.com",
            "stellarAddress": "foo_bar@baz.com*bitgo.com"
          }
        }.to_json
      }

      let(:request_method) { :get }
      let(:request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] }

      it 'requests bitgo client and get balance' do
        result = wallet.load_balance!
        expect(result).to be_a(BigDecimal)
        expect(result).to eq('5'.to_d)
      end
    end

  context 'build raw transaction' do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    before do
      wallet.configure(settings)
    end

    context 'raw transaction for base coins' do
      before do
        stub_request(:post, uri + request_path)
        .with(body: request_body, headers: request_headers(settings[:wallet]))
        .to_return(status: 200, body: response_body)
      end

     let(:response_body) {
      {
        "txHex": "0100000001381e2e88900cd7d87dc1b23267",
        "txInfo": {
          "nP2SHInputs": 0,
          "nSegwitInputs": 1,
          "nOutputs": 1,
          "unspents": [{
            "chain": 11,
            "index": 4,
            "redeemScript": "002079f8f73a092df7a46b3a330f2c705457b538",
            "witnessScript": "522100c2ab193e81a1bca9ebb38ccff7329cc95655953ae",
            "id": "d9c359f727a22320b214afa9184f3008799dc16732b2c17dd8d70c90882e1e38:0",
            "address": "2Myd3DDQE7S8NfQgUFN2a9kAjNQrLVWBNwe",
            "value": 9462
            }],
            "changeAddresses": [],
            "walletAddressDetails": {}
          },
          "feeInfo": {"size": 183, "fee": 1462, "feeRate": 7989, "payGoFee":0, "payGoFeeString": "0"}
         }.to_json
        }

        let(:request_method) { :post }
        let(:request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/tx/build' }
        let(:transaction) do
          Peatio::Transaction.new(amount: 1.1, to_address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
        end

        let(:request_body) {
          {
            "recipients": [{
              "address": transaction.to_address,
              "amount": '110000000'
              }]
            }.to_json
          }

        it 'builds raw transaction for base coins' do
          result = wallet.build_raw_transaction(transaction)
          expect(result['feeInfo'].to_json).to eq({:size=>183, :fee=>1462, :feeRate=>7989, :payGoFee=>0, :payGoFeeString=>"0"}.to_json)
        end
      end

      context 'raw transaction for XRP' do
        before do
          stub_request(:post, uri + request_path)
          .with(body: request_body, headers: request_headers(settings[:wallet]))
          .to_return(status: 200, body: response_body)
        end

        let(:response_body) {
          {
            "txInfo":
            {
              "TransactionType": "Payment",
              "Account": "rB6xgW2yEnnhJyKND6CRKqMz4Z4Rh1bZcZ",
              "Destination": "rHvyaXBYYphVzWt79jJvpgxXYE6MHBXQxk",
              "DestinationTag": 0,
              "Amount": "12000000",
              "Flags": 2147483648,
              "Fee": "45",
              "Sequence": 4
            },
            "feeInfo":
            {
              "date": "2020-02-24T09:50:16.587Z",
              "height": 4888341,
              "xrpBaseReserve": "20000000",
              "xrpIncReserve": "5000000",
              "xrpOpenLedgerFee": "10",
              "xrpMedianFee": "5000",
              "medianFee": "20000000",
              "baseReserve": "5000000",
              "incReserve": "10",
              "openLedgerFee": "5000"
            }
          }.to_json
        }

        let(:request_method) { :post }
        let(:request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/tx/build' }

        let(:transaction) do
          Peatio::Transaction.new(amount: 1.1, to_address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
        end

        let(:request_body) {
          {
            "recipients": [{
              "address": transaction.to_address,
              "amount": '110000000'
              }]
            }.to_json
          }

        it 'builds raw transaction for xrp' do
          result = wallet.build_raw_transaction(transaction)
          expect(result['txInfo']['Fee']).to eq('45')
        end
      end
   end

   context 'create_transaction!' do
     around do |example|
       WebMock.disable_net_connect!
       example.run
       WebMock.allow_net_connect!
     end

     context 'create transaction for base coins' do
      context 'with substract fee' do
        before do
          stub_request(:post, uri + first_request_path)
          .with(body: first_request_body, headers: request_headers(settings[:wallet]))
          .to_return(status: 200, body: first_response_body)
        end

        let(:first_request_body) {
          {
            "recipients": [{
              "address": transaction.to_address,
              "amount": '110000000'
              }]
            }.to_json
          }

        let(:first_response_body) {
            {
              "txHex": "0100000001381e2e88900cd7d87dc1b23267",
              "txInfo": {
                "nP2SHInputs": 0,
                "nSegwitInputs": 1,
                "nOutputs": 1,
                "unspents": [{
                  "chain": 11,
                  "index": 4,
                  "redeemScript": "002079f8f73a092df7a46b3a330f2c705457b538",
                  "witnessScript": "522100c2ab193e81a1bca9ebb38ccff7329cc95655953ae",
                  "id": "d9c359f727a22320b214afa9184f3008799dc16732b2c17dd8d70c90882e1e38:0",
                  "address": "2Myd3DDQE7S8NfQgUFN2a9kAjNQrLVWBNwe",
                  "value": 9462
                  }],
                  "changeAddresses": [],
                  "walletAddressDetails": {}
                },
                "feeInfo": {"size": 183, "fee": 1462, "feeRate": 7989, "payGoFee":0, "payGoFeeString": "0"}
              }.to_json
        }

        let(:first_request_method) { :post }
        let(:first_request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/tx/build' }

        before do
          stub_request(:post, uri + second_request_path)
          .with(body: second_request_body, headers: request_headers(settings[:wallet]))
          .to_return(status: 200, body: second_response_body)
        end

        let(:second_response_body) {
          {
            "transfer": {},
            "txid": "x123123483791e27387sd945384554ui34jw",
            "tx": "a234343234",
            "status": "signed"
          }.to_json
        }

        let(:transaction) do
          Peatio::Transaction.new(amount: 1.1, to_address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
        end

        before do
          wallet.configure(settings)
        end

        let(:second_request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/sendcoins'}

        let(:second_request_body) { {
          "address": transaction.to_address, "amount": '109998538',
          "walletPassphrase": settings[:wallet][:secret]
         }.to_json
        }

        it 'requests bitgo client and sends transaction ' do
          result = wallet.create_transaction!(transaction, subtract_fee: true)

          expect(result.amount).to eq(1.1)
          expect(result.to_address).to eq('2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
          expect(result.hash).to eq('x123123483791e27387sd945384554ui34jw')
          expect(result.status).to eq('pending')
        end
      end

      context 'without substract fee' do
        before do
          stub_request(:post, uri + request_path)
          .with(body: {}, headers: request_headers(settings[:wallet]))
          .to_return(status: 200, body: response_body)
        end

        let(:response_body) {
          {
            "transfer": {},
            "txid": "x123123483791e27387sd945384554ui34jw",
            "tx": "a234343234",
            "status": "signed"
          }.to_json
        }

        let(:transaction) do
          Peatio::Transaction.new(amount: 1.1, to_address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
        end

        before do
          wallet.configure(settings)
        end

        let(:request_path) { '/tbtc/wallet/' + settings[:wallet][:wallet_id] + '/sendcoins'}

        let(:request_body) { {
          "address": transaction.to_address, "amount": '110000000000000',
          "walletPassphrase": settings[:wallet][:secret]
        }.to_json
      }

      it 'requests bitgo client and sends transaction ' do
        result = wallet.create_transaction!(transaction)
        expect(result.amount).to eq(1.1)
        expect(result.to_address).to eq('2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
        expect(result.hash).to eq('x123123483791e27387sd945384554ui34jw')
        expect(result.status).to eq('pending')
      end
    end
  end

  context 'create eth transaction' do
      let(:settings) do
      {
        wallet: {
          address: '0x2b9fBC10EbAeEc28a8Fc10069C0BC29E45eBEB9C',
          uri: uri,
          secret: 'changeme',
          access_token: 'v2x0b53e612518e5ea625eb3c24175438b37f56bc1f82e9c9ba3b038c91b0c72e67',
          wallet_id: '5a7d9f52ba1923b107b80baabe0c3574',
          testnet: true
        },
        currency: {
          id: 'eth',
          base_factor: 1_000_000_000_000_000_000,
          code: 'eth',
          options: {
            gas_limit: 21_000,
            gas_price: 1_000_000_000
          }
        }
      }
      end

      let(:response_body) {
        {
          "transfer": {},
          "txid": "x123123483791e27387sd945384554ui34jw",
          "tx": "a234343234",
          "status": "signed"
        }.to_json
      }

      before do
        wallet.configure(settings)
      end

      let(:transaction) do
        Peatio::Transaction.new(amount: 1.1, to_address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
      end

      let(:request_method) { :post }
      let(:request_path) { '/teth/wallet/' + settings[:wallet][:wallet_id] + '/sendcoins' }

      before do
        stub_request(:post, uri + request_path)
        .with(body: request_body, headers: request_headers(settings[:wallet]))
        .to_return(status: 200, body: response_body)
      end

      context 'with substract fee' do
        let(:request_body) { {
            "address": transaction.to_address, "amount": '1100000000000000000',
            "walletPassphrase": settings[:wallet][:secret], "gas": settings[:currency][:options][:gas_limit],
            "gasPrice": settings[:currency][:options][:gas_price]
          }.to_json
        }

        it 'creates eth transaction' do
          result = wallet.create_transaction!(transaction, subtract_fee: true)
          expect(result.amount).to eq(1.1)
          expect(result.to_address).to eq('2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
          expect(result.hash).to eq('x123123483791e27387sd945384554ui34jw')
          expect(result.status).to eq('pending')
        end
      end

      context 'without substract fee' do
        let(:request_body) { {
          "address": transaction.to_address, "amount": '1100000000000000000',
          "walletPassphrase": settings[:wallet][:secret], "gas": settings[:currency][:options][:gas_limit],
          "gasPrice": settings[:currency][:options][:gas_price]
        }.to_json
        }

        it 'creates eth transaction' do
          result = wallet.create_transaction!(transaction)
          expect(result.amount).to eq(1.1)
          expect(result.to_address).to eq('2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf')
          expect(result.hash).to eq('x123123483791e27387sd945384554ui34jw')
          expect(result.status).to eq('pending')
        end
      end
    end
  end
end
