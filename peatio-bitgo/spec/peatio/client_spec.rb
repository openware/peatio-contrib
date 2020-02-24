RSpec.describe Peatio::Bitgo::Client do
  let(:uri) { 'http://localhost:3000/api/v2' }
  let(:access_token) { SecureRandom.hex(16) }
  before(:all) { WebMock.disable_net_connect! }
  after(:all) { WebMock.allow_net_connect! }

  subject { Peatio::Bitgo::Client.new(uri, access_token) }

  context :initialize do
    it { expect{ subject }.not_to raise_error }
  end

  context :undefined_method do
    it do
      expect { subject.rest_api(:undefined_method, '') }.to \
               raise_error(Peatio::Bitgo::Client::Error)
    end
  end

  context :invalid_wallet_id do
    before do
      stub_request(:post, uri)
      .with(body: {})
      .to_return(status: 400, body: response_body)
    end

    let(:response_body) {
      {
        "error": "string",
        "requestId": "string",
        "context": {
          "id": "585951a5df8380e0e3063e9f12345678"
        },
        "name": "InvalidWalletId"
      }.to_json
    }

    it do
      expect{ subject.rest_api(:post, '') }.to \
              raise_error(Peatio::Bitgo::Client::ConnectionError)
    end
  end

  context :create_address do
    before do
      stub_request(:post, "#{uri}#{request_path}")
      .with(body: {})
      .to_return(status: 200, body: response_body)
    end

    let(:response_body) {
      { address: "2MySruptM4SgZF49KSc3x5KyxAW61ghyvtc", secret: 'changeme',
        id: 'd9c359f727a22320b214afa9184f3'
      }.to_json
    }

    let(:request_path) { '/tbtc/wallet/d9c359f727a22320b214afa9184f3/address' }

    it { expect{ subject.rest_api(:post, request_path) }.not_to raise_error }
    it { expect(subject.rest_api(:post, request_path)).to eq({"address"=>"2MySruptM4SgZF49KSc3x5KyxAW61ghyvtc", "id"=>"d9c359f727a22320b214afa9184f3",
                                                              "secret"=>"changeme"}) }
  end

  context :connectionerror do
    before do
      Faraday::Connection.any_instance.expects(:post).raises(Faraday::Error).once
    end

    it do
      expect{ subject.rest_api(:post, '/') }.to \
              raise_error(Peatio::Bitgo::Client::ConnectionError)
    end
  end
end
