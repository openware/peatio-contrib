RSpec.describe Peatio::Ripple::Wallet do
  let(:wallet) { Peatio::Ripple::Wallet.new }

  let(:uri) { 'http://user:password@127.0.0.1:5005' }
  let(:uri_without_authority) { 'http://127.0.0.1:5005' }

  let(:settings) do
    {
      wallet: { address: 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh',
                uri:     uri,
                secret:  'password' },
      currency: { id: :xrp,
                  base_factor: 100_000,
                  options: {} }
    }
  end

  before do
    wallet.configure(settings)
  end

  context :configure do
    let(:unconfigured_wallet) { Peatio::Ripple::Wallet.new }

    it 'requires wallet' do
      expect { unconfigured_wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it 'requires currency' do
      expect { unconfigured_wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it 'sets settings attribute' do
      unconfigured_wallet.configure(settings)
      expect(unconfigured_wallet.settings).to eq(settings.slice(*Peatio::Ripple::Wallet::SUPPORTED_SETTINGS))
    end
  end

  context :create_address! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    before do
      PasswordGenerator.stubs(:generate).returns('pass@word')
      SecureRandom.stubs(:random_number).returns(1)
    end

    it 'request rpc and creates new address' do
      result = wallet.create_address!(uid: 'UID123')
      expect(result.symbolize_keys).to eq(address: 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh?dt=1', secret: settings.dig(:wallet, :secret))
    end
  end

  context :create_transaction! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response_fee) do
      fee_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_block) do
      block_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_sign) do
      sign_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_submit) do
      submit_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:fee_file) do
      File.join('spec', 'resources', 'fee', 'response.json')
    end

    let(:block_file) do
      File.join('spec', 'resources', 'ledger', '19352015.json')
    end

    let(:sign_file) do
      File.join('spec', 'resources', 'sign', 'response.json')
    end

    let(:submit_file) do
      File.join('spec', 'resources', 'submit', 'response.json')
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      1,
                      method: :fee,
                      params:  {} }.to_json)
        .to_return(body: response_fee.to_json)

      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      2,
                      method: :ledger,
                      params:  [{ ledger_index: 'validated' }] }.to_json)
        .to_return(body:  response_block.to_json)

      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      3,
                      method: :sign,
                      params:  [{ "secret":"password",
                                 "tx_json":
                                 { "Account":"rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh",
                                   "Amount":"11000",
                                   "Fee":"10",
                                   "Destination":"rB94e2mZZcApwEFeW6oWuME351w1yQpJQy",
                                   "DestinationTag":0,
                                   "TransactionType":"Payment",
                                   "LastLedgerSequence":19352019 } }] }.to_json)
        .to_return(body: response_sign.to_json)

      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      4,
                      method: :submit,
                      params:  [{ tx_blob: '12000022800000002400000001201B012C8C2361400000000098968068400000000000000A732102B9C6E7141E6C573B4B458EDA44A1E823C404AA16142C1F26EF714163A3F2FB6E74473045022100C7743499C9A1E1D722ED2D4B75D5AB858F603AD0E4DDA33DAAEEC604B46DAD8B022026A2E6F3C326E91CD3301BD93CFEB4E2AAAFDFB45D39A3001BA0203B83E9516281141F02F845784D34EF689AE436709184E69BF17A8883146F46A80656A321D5A1E2224A73DA60C23F218A93' }] }.to_json)
        .to_return(body:  response_submit.to_json)
    end

    let(:transaction) do
      Peatio::Transaction.new(amount: 0.11, to_address: 'rB94e2mZZcApwEFeW6oWuME351w1yQpJQy')
    end

    it 'requests rpc and sends transaction without subtract fees' do
      result = wallet.create_transaction!(transaction)
      expect(result.amount).to eq(0.11)
      expect(result.to_address).to eq('rB94e2mZZcApwEFeW6oWuME351w1yQpJQy')
      expect(result.hash).to eq('F9CB4575C9482D9480AAE2DAF56BE133B19D82011D1F23A98CFA100ECE8FF13E')
    end
  end

  context :load_balance! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'account_info', 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh.json')
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '2.0',
                      id:      1,
                      method:  :account_info,
                      params:  [{"account":"rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh","ledger_index":"validated","strict":true}] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'requests rpc with getbalance call' do
      result = wallet.load_balance!
      expect(result).to be_a(BigDecimal)
      expect(result).to eq(0.2309708769018e8)
    end
  end
end
