# frozen_string_literal: true

describe Peatio::Electrum::Wallet do
  let(:wallet) { Peatio::Electrum::Wallet.new }
  let(:uri) { 'http://user:pass@127.0.0.1:7000' }
  let(:settings) do
    {
      wallet: {
        address: 'something',
        uri: uri
      },
      currency: {
        id: :btc,
        options: {}
      }
    }
  end

  before { wallet.configure(settings) }
  include_context 'mocked electrum server'

  before(:each) do
    allow(wallet.client).to receive(:new_id).and_return(42)
  end

  context :configure do
    let(:unconfigured_wallet) { Peatio::Electrum::Wallet.new }

    it 'requires wallet' do
      expect { unconfigured_wallet.configure(settings.except(:wallet)) }
        .to raise_error(Peatio::Wallet::MissingSettingError)

      expect { unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it 'requires currency' do
      expect { unconfigured_wallet.configure(settings.except(:currency)) }
        .to raise_error(Peatio::Wallet::MissingSettingError)

      expect { unconfigured_wallet.configure(settings) }.to_not raise_error
    end

    it 'sets settings attribute' do
      unconfigured_wallet.configure(settings)
      expect(unconfigured_wallet.settings)
        .to eq(settings.slice(*Peatio::Electrum::Wallet::SUPPORTED_SETTINGS))
    end
  end

  context :create_address! do
    it 'creates a new address' do
      result = wallet.create_address!(uid: 'UID123')
      expect(result.symbolize_keys).to eq(address: 'miACDRY1sVVmznApZv1sSkQXZyhAHNcKHW')
    end
  end

  context :create_transaction! do
    let(:transaction) do
      Peatio::Transaction.new(amount: 0.001, to_address: 'mkHS9ne12qx9pS9VojpwU5xtRd4T7X7ZUt')
    end

    it 'requests rpc and sends transaction without subtract fees' do
      result = wallet.create_transaction!(transaction)
      expect(result.amount).to eq(0.001)
      expect(result.to_address).to eq('mkHS9ne12qx9pS9VojpwU5xtRd4T7X7ZUt')
      expect(result.hash).to eq('79e98ec6cb4952906d8b119dec4224e47fc9b0731e08f6a8a2209853b7930ce4')
    end
  end

  context :load_balance! do
    it 'requests rpc with getbalance call' do
      result = wallet.load_balance!
      expect(result).to be_a(BigDecimal)
      expect(result).to eq('0.011'.to_d)
    end
  end
end
