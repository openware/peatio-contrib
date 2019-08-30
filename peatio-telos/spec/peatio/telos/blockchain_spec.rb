# frozen_string_literal: true

RSpec.describe Peatio::Telos::Blockchain do
  context :features do
    it "defaults" do
      blockchain1 = Peatio::Telos::Blockchain.new
      expect(blockchain1.features).to eq Peatio::Telos::Blockchain::DEFAULT_FEATURES
    end

    it "override defaults" do
      blockchain2 = Peatio::Telos::Blockchain.new(cash_addr_format: true)
      expect(blockchain2.features[:cash_addr_format]).to be_truthy
    end

    it "custom feautures" do
      blockchain3 = Peatio::Telos::Blockchain.new(custom_feature: :custom)
      expect(blockchain3.features.keys).to contain_exactly(:cash_addr_format, :case_sensitive)
    end
  end

  context :configure do
    let(:blockchain) { Peatio::Telos::Blockchain.new }
    let(:server) { "http://127.0.0.1:8888" }
    let(:currencies) do
      [{id: "telos", name: "telos", symbol: "T", options: {telos_token_name: "TLOS"}},
       {id: "telos", name: "telos", symbol: "t", options: {telos_token_name: "TLS"}}]
    end

    it "default settings" do
      expect(blockchain.settings).to eq({})
    end

    it "currencies and server configuration" do
      settings = {server: server,
                   currencies: currencies,
                   something: :custom}
      blockchain.configure(settings)
      expect(blockchain.settings).to eq(settings.slice(*Peatio::Blockchain::Abstract::SUPPORTED_SETTINGS))
    end
  end

  context :latest_block_number do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    let(:server) { "http://127.0.0.1:8888" }
    let(:blockchain) do
      Peatio::Telos::Blockchain.new.tap {|b| b.configure(server: server) }
    end
    let(:response) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:response_file) do
      File.join("spec", "resources", "getinfo", "response.json")
    end

    it "returns latest block number" do
      block_number = 49_582

      stub_request(:post, "http://127.0.0.1:8888/v1/chain/get_info")
        .to_return(body: response.to_json)

      expect(blockchain.latest_block_number).to eq(block_number)
    end

    let(:error) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
  end

  context :load_balance_of_address! do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    let(:server) { "http://127.0.0.1:8888" }
    let(:currency) do
      {id: "telos", name: "telos", symbol: "s", options: {telos_token_name: "TLOS"}}
    end
    let(:blockchain) do
      Peatio::Telos::Blockchain.new.tap {|b| b.configure(server: server, currencies: [currency]) }
    end
    let(:response) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:response_file) do
      File.join("spec", "resources", "getbalance", "response.json")
    end

    before do
      stub_request(:post, "http://127.0.0.1:8888/v1/chain/get_currency_balance")
        .with(body: {"account" => "something", "code" => "eosio.token"})
        .to_return(body: response.to_json)
    end

    it "requests rpc telos get account for get balance" do
      result = blockchain.load_balance_of_address!("something", "telos")
      expect(result).to eq("10000.6256".to_d)
    end
  end

  context :fetch_block! do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    let(:response_file) do
      File.join("spec", "resources", "getblock", "response.json")
    end
    let(:block_data) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:start_block)   { block_data.first["block_num"] }
    let(:latest_block)  { block_data.last["block_num"] }

    before do
      block_data.each do |blk|
        # stub get_block
        stub_request(:post, "http://127.0.0.1:8888/v1/chain/get_block")
          .with(body: {"block_num_or_id" => blk["block_num"]})
          .to_return(body: blk.to_json)
      end
    end

    let(:server) { "http://127.0.0.1:8888" }
    let(:currency) do
      {id: "telos", name: "telos", symbol: "T", options: {telos_token_name: "TLOS"}}
    end

    let(:blockchain) do
      Peatio::Telos::Blockchain.new.tap {|b| b.configure(server: server, currencies: [currency]) }
    end

    context "first block" do
      subject { blockchain.fetch_block!(start_block) }
      it "builds expected number of transactions" do
        expect(subject.count).to eq(3)
      end
      it "all transactions are valid" do
        expect(subject.all?(&:valid?)).to be_truthy
      end
    end

    context "last block" do
      subject { blockchain.fetch_block!(latest_block) }
      it "builds expected number of transactions" do
        expect(subject.count).to eq(2)
      end
      it "all transactions are valid" do
        expect(subject.all?(&:valid?)).to be_truthy
      end
    end
  end

  context :build_transaction do
    let(:response_file) do
      File.join("spec", "resources", "gettransaction", "response_valid.json")
    end
    let(:tx_hash) do
      response_file
        .yield_self {|file_path| File.open(file_path) }
        .yield_self {|file| JSON.load(file) }
    end
    let(:expected_transactions) do
      [{hash: "8a54dfb8094a11ddce48fdb9d53a881ceb92d1302cc66f4a190d597b5c7243b7",
        txout: 0,
        to_address: "laomaoziren1?memo=ID6816C3C8C5",
        amount: 0.1e-3,
        currency_id: "telos",
        status: "success"}]
    end
    let(:currency) do
      {id: "telos", name: "telos", symbol: "T", options: {telos_token_name: "TLOS"}}
    end
    let(:blockchain) do
      Peatio::Telos::Blockchain.new.tap {|b| b.configure(currencies: [currency]) }
    end

    it "builds formatted transactions for passed transaction" do
      expect(blockchain.send(:build_transaction, tx_hash)).to contain_exactly(*expected_transactions)
    end

    context "multiple currencies" do
      let(:response_file_multi) do
        File.join("spec", "resources", "gettransaction", "response_multi_cur.json")
      end
      let(:tx_hash_multi) do
        response_file
          .yield_self {|file_path| File.open(file_path) }
          .yield_self {|file| JSON.load(file) }
      end
      let(:expected_transactions) do
        [{hash: "8a54dfb8094a11ddce48fdb9d53a881ceb92d1302cc66f4a190d597b5c7243b7",
          txout: 0,
          to_address: "laomaoziren1?memo=ID6816C3C8C5",
          amount: 0.1e-3,
          currency_id: "telos",
          status: "success"},
         {hash: "8a54dfb8094a11ddce48fdb9d53a881ceb92d1302cc66f4a190d597b5c7243b7",
          txout: 1,
          to_address: "laomaoziren1?memo=ID6816C3C8C5",
          amount: 0.1e-3,
          currency_id: "telos2",
          status: "success"}]
      end
      let(:currencies) do
        [{id: "telos", name: "telos", symbol: "T", options: {telos_token_name: "TLOS"}},
         {id: "telos2", name: "telos2", symbol: "t", options: {telos_token_name: "TLS"}}]
      end
      let(:blockchain) do
        Peatio::Telos::Blockchain.new.tap do |b|
          b.configure(currencies: currencies)
        end
      end

      it "builds formatted transactions for passed transaction per each currency" do
        expect(blockchain.send(:build_transaction, tx_hash_multi)).to contain_exactly(*expected_transactions)
      end
    end

    context "two vout transaction" do
      let(:response_file) do
        File.join("spec", "resources", "gettransaction", "response_vout.json")
      end
      let(:tx_hash) do
        response_file
          .yield_self {|file_path| File.open(file_path) }
          .yield_self {|file| JSON.load(file) }
      end

      let(:expected_transactions) do
        [{hash: "8a54dfb8094a11ddce48fdb9d53a881ceb92d1302cc66f4a190d597b5c7243b7",
          txout: 0,
          to_address: "laomaoziren1?memo=ID6816C3C8C5",
          amount: 0.1e-3,
          currency_id: "telos",
          status: "success"},
         {hash: "8a54dfb8094a11ddce48fdb9d53a881ceb92d1302cc66f4a190d597b5c7243b7",
          txout: 1,
          to_address: "laomaoziren2?memo=ID6816C3C8C5",
          amount: 0.2e-3,
          currency_id: "telos",
          status: "success"}]
      end

      it "builds formatted transactions for each vout" do
        expect(blockchain.send(:build_transaction, tx_hash)).to contain_exactly(*expected_transactions)
      end
    end
  end
end
