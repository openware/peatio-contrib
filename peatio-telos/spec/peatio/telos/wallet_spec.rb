# frozen_string_literal: true

RSpec.describe Peatio::Telos::Wallet do
  let(:wallet) { Peatio::Telos::Wallet.new }

  context :configure do
    let(:settings) { {wallet: {}, currency: {id: "telos", name: "telos", symbol: "T", base_factor: 4, precision: 4, options: {telos_token_name: "TLOS"}}} }
    let(:settings2) { {wallet: {}, currency: {options: {}}} }

    it "requires wallet" do
      expect { wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it "requires currency" do
      expect { wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it "requires telos_token_name" do
      expect { wallet.configure(settings2) }.to raise_error(*Peatio::Telos::Wallet::MissingTokenNameError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it "sets settings attribute" do
      wallet.configure(settings)
      expect(wallet.settings).to eq(settings.slice(*Peatio::Telos::Wallet::SUPPORTED_SETTINGS))
    end
  end

  context :create_address! do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    let(:uri) { "http://127.0.0.1:8888" }

    let(:address) { "someaddress?memo=U123343" }

    let(:uid) { "U123343" }

    let(:settings) do
      {
        wallet:
          {address: "someaddress",
            uri:     uri,
            secret:  "changeme"},
        currency: {options: {telos_token_name: "TLOS"}}
      }
    end

    before do
      wallet.configure(settings)
    end

    it "request create new address" do
      result = wallet.create_address!(uid: uid)
      expect(result).to eq(address: address, secret: "changeme")
    end
  end

  context :create_transaction! do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    let(:telos) do
      Peatio::Currency.find_by(id: :telos)
    end

    let(:uri) { "http://127.0.0.1:8888" }

    let(:transaction) do
      Peatio::Transaction.new(amount: 1.1, to_address: "something", status: "success")
    end

    let(:settings) do
      {
        wallet: {address: "someaddress",
                 uri:     uri,
                 secret:  "changeme"},
        currency: {id: "telos", name: "telos", symbol: "T", base_factor: 4, precision: 4, options: {telos_token_name: "TLOS"}}
      }
    end

    before do
      wallet.configure(settings)
    end
    let(:response_info) do
      file_info
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:file_info) do
      File.join("spec", "resources", "getinfo", "response.json")
    end
    let(:response_block) do
      block_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:block_file) do
      File.join("spec", "resources", "pushtransaction", "response_get_block.json")
    end

    let(:json_to_bin_request_body) do
      {
        "code": "eosio.token",
        "action": "transfer",
        "args": {
          "from": "someaddress",
          "to": "something",
          "quantity": "1.1000 TLOS",
          "memo": "transfer from peatio"
        }
      }
    end
    let(:bin_file) do
      File.join("spec", "resources", "pushtransaction", "response_json_to_bin.json")
    end
    let(:response_bin) do
      bin_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end

    let(:sign_request_body) do
      [
        {
          "ref_block_num": 34_582,
          "ref_block_prefix": 1_753_012_779,
          "max_cpu_usage_ms": 0,
          "max_net_usage_words": 0,
          "expiration": "2018-05-24T16:30:32.000000",
          "region": "0",
          "actions": [
            {
              "account": "eosio.token",
              "name": "transfer",
              "authorization": [
                {
                  "actor": "someaddress",
                  "permission": "active"
                }
              ],
              "data": "0000000000ea305500000000487a2b9d102700000000000004454f53000000001163726561746564206279206e6f70726f6d"
            }
          ],
          "signatures": []
        },
        [
          "changeme"
        ], "e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473"
      ]
    end
    let(:sign_file) do
      File.join("spec", "resources", "pushtransaction", "response_sign.json")
    end
    let(:response_sign) do
      sign_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end

    let(:push_request_body) do
      {
        "compression": "none",
        "transaction": {
          "actions": [
            {
              "account": "eosio.token",
              "name": "transfer",
              "authorization": [
                {
                  "actor": "someaddress",
                  "permission": "active"
                }
              ],
              "data": "0000000000ea305500000000487a2b9d102700000000000004454f53000000001163726561746564206279206e6f70726f6d"
            }
          ],
          "expiration": "2018-05-24T16:30:32.000000",
          "max_cpu_usage_ms": 0,
          "max_net_usage_words": 0,
          "delay_sec": 0,
          "ref_block_num": 34_582,
          "ref_block_prefix": 1_753_012_779,
          "context_free_actions": [],
          "context_free_data": [],
          "signatures": ["SIG_K1_Khn918pY1NHmnbF41bsqFE7sPYrniZPtTns68qUo3m92jp6gbegkpRHYSp9RH95T3u82XUvjZLM33AP83ZqiGApBo7JnBF"],
          "transaction_extensions": [],
        },
        "signatures": ["SIG_K1_Khn918pY1NHmnbF41bsqFE7sPYrniZPtTns68qUo3m92jp6gbegkpRHYSp9RH95T3u82XUvjZLM33AP83ZqiGApBo7JnBF"]
      }
    end
    let(:tx_file) do
      File.join("spec", "resources", "pushtransaction", "response.json")
    end
    let(:response_tx) do
      tx_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:tx_example) do
      Peatio::Transaction.new(amount: 1.1, status: "success", to_address: "something", hash: "015ba92c7ad7294f0d70c772e7ba6ed678b11734418bf9ec48b001ce65c48e2")
    end

    it "requests rpc and sends transaction" do
      stub_request(:post, "http://127.0.0.1:8888/v1/chain/abi_json_to_bin")
        .with(body: json_to_bin_request_body.to_json)
        .to_return(body: response_bin.to_json)

      stub_request(:post, "http://127.0.0.1:8888/v1/chain/get_info")
        .to_return(body: response_info.to_json)

      stub_request(:post, "http://127.0.0.1:8888/v1/chain/get_block")
        .with(body: {"block_num_or_id" => 34_582})
        .to_return(body: response_block.to_json)

      stub_request(:post, "http://127.0.0.1:8900/v1/wallet/sign_transaction")
        .with(body: sign_request_body.to_json)
        .to_return(body: response_sign.to_json)

      stub_request(:post, "http://127.0.0.1:8888/v1/chain/push_transaction")
        .with(body: push_request_body.to_json)
        .to_return(body: response_tx.to_json)

      result = wallet.create_transaction!(transaction)
      expect(result.amount).to eq(tx_example.amount)
      expect(result.status).to eq(tx_example.status)
      expect(result.to_address).to eq(tx_example.to_address)
      expect(result.hash).to eq(tx_example.hash)
    end
  end

  context :load_balance_of_address! do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    let(:hot_wallet_telos) { Peatio::Wallet.find_by(currency: :telos, kind: :hot) }
    let(:settings1) do
      {
        wallet: {address: "something",
                  uri:     "http://127.0.0.1:8888",
                  secret:  "changeme"},
        currency: {id: "telos", name: "telos", symbol: "e", base_factor: 4, precision: 4, options: {telos_token_name: "TLOS"}}
      }
    end
    let(:response_file) do
      File.join("spec", "resources", "getbalance", "response.json")
    end
    let(:response) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    before do
      stub_request(:post, "http://127.0.0.1:8888/v1/chain/get_currency_balance")
        .with(body: {"account" => "something", "code" => "eosio.token"})
        .to_return(body: response.to_json)
    end

    it "requests rpc telos get account for get balance" do
      wallet.configure(settings1)
      result = wallet.load_balance!
      expect(result).to eq("10000.6256".to_d)
    end
  end
end
