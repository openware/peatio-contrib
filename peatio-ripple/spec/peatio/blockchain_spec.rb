RSpec.describe Peatio::Ripple::Blockchain do
  context :features do
    it 'defaults' do
      blockchain1 = Peatio::Ripple::Blockchain.new
      expect(blockchain1.features).to eq Peatio::Ripple::Blockchain::DEFAULT_FEATURES
    end

    it 'override defaults' do
      blockchain2 = Peatio::Ripple::Blockchain.new(cash_addr_format: true)
      expect(blockchain2.features[:cash_addr_format]).to be_truthy
    end

    it 'custom feautures' do
      blockchain3 = Peatio::Ripple::Blockchain.new(custom_feature: :custom)
      expect(blockchain3.features.keys).to contain_exactly(*Peatio::Ripple::Blockchain::SUPPORTED_FEATURES)
    end
  end

  context :configure do
    let(:blockchain) { Peatio::Ripple::Blockchain.new }
    it 'default settings' do
      expect(blockchain.settings).to eq({})
    end

    it 'currencies and server configuration' do
      currencies = [{ id: :xrp,
                      base_factor: 100_000,
                      options: {} }]
      settings = { server: 'http://user:password@127.0.0.1:5005',
                    currencies: currencies,
                    something: :custom }
      blockchain.configure(settings)
      expect(blockchain.settings).to eq(settings.slice(*Peatio::Blockchain::Abstract::SUPPORTED_SETTINGS))
    end
  end

  context :latest_block_number do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:5005' }
    let(:server_without_authority) { 'http://127.0.0.1:5005' }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_error) do
      response_error_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'ledger', '19352015.json')
    end

    let(:response_error_file) do
      File.join('spec', 'resources', 'methodnotfound', 'error.json' )
    end

    let(:blockchain) do
      Peatio::Ripple::Blockchain.new.tap {|b| b.configure(server: server)}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      1,
                      method: :ledger,
                      params:  [{ ledger_index: 'validated' }] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'returns latest block number' do
      expect(blockchain.latest_block_number).to eq(19352015)
    end

    it 'raises error if there is error in response body' do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      1,
                      method: :ledger,
                      params:  [{ ledger_index: 'validated' }] }.to_json)
        .to_return(body:  response_error.to_json)
      expect{ blockchain.latest_block_number }.to raise_error(Peatio::Blockchain::ClientError)
    end
  end

  context :build_transaction do

    let(:raw_transaction) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'transaction', '3DF6024FE1190A5D7F432924FDFBDC109F8AF78E55FB5CCE6A6B49245F2EA235.json')
    end

    context 'simple ripple tx' do
      let(:expected_transactions) do
        [{:hash=>"3DF6024FE1190A5D7F432924FDFBDC109F8AF78E55FB5CCE6A6B49245F2EA235",
          :txout=>0,
          :to_address=>"rno4GxpYvfs5yb9H1jeMkWi2DEUqiC7Sdp?dt=1",
          :status=>"success",
          :currency_id=>currency[:id],
          :amount=>0.2781499998e6}]
      end

      let(:currency) do
        { id: :xrp,
          base_factor: 100_000,
          options: {} }
      end

      let(:blockchain) do
        Peatio::Ripple::Blockchain.new.tap { |b| b.configure(currencies: [currency]) }
      end

      it 'builds formatted transactions for passed transaction' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context 'multiple currencies' do
      let(:currency1) do
        { id: :xrp1,
          base_factor: 100_000,
          options: {} }
      end

      let(:currency2) do
        { id: :xrp2,
          base_factor: 100_000,
          options: {} }
      end

      let(:expected_transactions) do
        [{:hash=>"3DF6024FE1190A5D7F432924FDFBDC109F8AF78E55FB5CCE6A6B49245F2EA235",
          :txout=>0,
          :to_address=>"rno4GxpYvfs5yb9H1jeMkWi2DEUqiC7Sdp?dt=1",
          :status=>"success",
          :currency_id=>currency1[:id],
          :amount=>0.2781499998e6},
          {:hash=>"3DF6024FE1190A5D7F432924FDFBDC109F8AF78E55FB5CCE6A6B49245F2EA235",
          :txout=>0,
          :to_address=>"rno4GxpYvfs5yb9H1jeMkWi2DEUqiC7Sdp?dt=1",
          :status=>"success",
          :currency_id=>currency2[:id],
          :amount=>0.2781499998e6}]
      end

      let(:blockchain) do
        Peatio::Ripple::Blockchain.new.tap do |b|
          b.configure(currencies: [currency1, currency2])
        end
      end

      it 'builds formatted transactions for passed transaction per each currency' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end
  end

  context :fetch_block! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:5005' }
    let(:server_without_authority) { 'http://127.0.0.1:5005' }

    let(:getblock_response_file) do
      File.join('spec', 'resources', 'ledger(transactions: true)', '19431573.json')
    end

    let(:getblock_response) do
      getblock_response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:blockchain) do
      Peatio::Ripple::Blockchain.new.tap {|b| b.configure(server: server)}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      1,
                      method:  :ledger,
                      params:  [{ "ledger_index":19431573, "transactions":true, "expand":true }] }.to_json)
        .to_return(body: getblock_response.to_json)
    end

    let(:currency) do
      { id: :xrp,
        base_factor: 100_000,
        options: {} }
    end

    let(:server) { 'http://user:password@127.0.0.1:19332' }
    let(:server_without_authority) { 'http://127.0.0.1:19332' }
    let(:blockchain) do
      Peatio::Ripple::Blockchain.new.tap { |b| b.configure(server: server, currencies: [currency]) }
    end

    subject { blockchain.fetch_block!(19431573) }

    it 'builds expected number of transactions' do
      expect(subject.count).to eq(4)
    end

    it 'all transactions are valid' do
      expect(subject.all?(&:valid?)).to be_truthy
    end
  end

  context :load_balance_of_address! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:19332' }
    let(:server_without_authority) { 'http://127.0.0.1:19332' }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'account_info', 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh.json')
    end

    let(:response_error) do
      response_error_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_error_file) do
      File.join('spec', 'resources', 'account_info', 'error.json')
    end

    let(:currency) do
      { id: 'xrp',
        base_factor: 100_000,
        options: {} }
    end

    let(:blockchain) do
      Peatio::Ripple::Blockchain.new.tap {|b| b.configure(server: server, currencies: [currency])}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      1,
                      method:  :account_info,
                      params:  [{"account":"rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh","ledger_index":"validated","strict":true}] }.to_json)
        .to_return(body: response.to_json)
    end

    context 'address with balance is defined' do
      it 'requests rpc account_info and finds address balance' do
        address = 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh'

        result = blockchain.load_balance_of_address!(address, :xrp)
        expect(result).to be_a(BigDecimal)
        expect(result).to eq(0.2309708769018e8)
      end
    end

    context 'undefined currency' do
      it 'raises Peario::Ripple::Blockchain::UndefinedCurrencyError' do
        address = 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh'
        expect{ blockchain.load_balance_of_address!(address, :xrp1)}.to raise_error(Peatio::Ripple::Blockchain::UndefinedCurrencyError)
      end
    end

    context 'client error is raised' do
      before do
        stub_request(:post, 'http://127.0.0.1:19332')
          .with(body: { jsonrpc: '2.0',
                        id:      1,
                        method:  :account_info,
                        params:  [{"account":"rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh","ledger_index":"validated","strict":true}] }.to_json)
          .to_return(body: response_error.to_json)
      end

      it 'raise wrapped client error' do
        expect{ blockchain.load_balance_of_address!('rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh', :xrp)}.to raise_error(Peatio::Blockchain::ClientError)
      end
    end
  end
end
