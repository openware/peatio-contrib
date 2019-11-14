RSpec.describe Peatio::Litecoin::Wallet do
  let(:wallet) { Peatio::Litecoin::Wallet.new }

  let(:uri) { 'http://user:password@127.0.0.1:19332' }
  let(:uri_without_authority) { 'http://127.0.0.1:19332' }

  let(:settings) do
    {
      wallet: { address: 'something',
                uri:     uri },
      currency: { id: :ltc,
                  base_factor: 100_000_000,
                  options: {} }
    }
  end

  before { wallet.configure(settings) }

  context :configure do
    let(:unconfigured_wallet) { Peatio::Litecoin::Wallet.new }

    it 'requires wallet' do
      expect{ unconfigured_wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect{ unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it 'requires currency' do
      expect{ unconfigured_wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect{ unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it 'sets settings attribute' do
      unconfigured_wallet.configure(settings)
      expect(unconfigured_wallet.settings).to eq(settings.slice(*Peatio::Litecoin::Wallet::SUPPORTED_SETTINGS))
    end
  end

  context :create_address! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'getnewaddress', 'response.json')
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :getnewaddress,
                      params:  [] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'request rpc and creates new address' do
      result = wallet.create_address!(uid: 'UID123')
      expect(result.symbolize_keys).to eq(address: 'QYfsoujRUQRbbSou1RbwHpJ4gp6kjh3xcM')
    end
  end

  context :create_transaction! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'sendtoaddress', 'response.json')
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :sendtoaddress,
                      params:  [transaction.to_address,
                                transaction.amount,
                                '',
                                '',
                                false] }.to_json)
        .to_return(body: response.to_json)
    end

    let(:transaction) do
      Peatio::Transaction.new(amount: 0.11, to_address: 'QRnrwkUBQ2E4ZJ3bj8jvn4Nwx4nJ2U7wXF')
    end

    it 'requests rpc and sends transaction without subtract fees' do
      result = wallet.create_transaction!(transaction)
      expect(result.amount).to eq(0.11)
      expect(result.to_address).to eq('QRnrwkUBQ2E4ZJ3bj8jvn4Nwx4nJ2U7wXF')
      expect(result.hash).to eq('1c5eb9dc533c369876b62f0b0bf8d69860473bb08e312316faf0ce35f2126fd7')
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
      File.join('spec', 'resources', 'getbalance', 'response.json')
    end

    before do
      stub_request(:post, uri_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :getbalance,
                      params:  [] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'requests rpc with getbalance call' do
      result = wallet.load_balance!
      expect(result).to be_a(BigDecimal)
      expect(result).to eq('6.00001982'.to_d)
    end
  end
end
