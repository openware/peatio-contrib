RSpec.describe Peatio::Ripple::Client do
  let(:uri) { "http://127.0.0.1:5005" }

  before(:all) { WebMock.disable_net_connect! }
  after(:all) { WebMock.allow_net_connect! }

  subject { Peatio::Ripple::Client.new(uri) }

  context :initialize do
    it { expect{ subject }.not_to raise_error }
  end

  context :json_rpc do
    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    context :getblockcount do
      let(:response_file) do
        File.join('spec', 'resources', 'ledger', '19352015.json')
      end

      before do
        stub_request(:post, uri)
          .with(body: { jsonrpc: '2.0',
                        id: 1,
                        method: :ledger,
                        params:  [{ ledger_index: "validated" }] }.to_json)
          .to_return(body: response.to_json)
      end

      it { expect { subject.json_rpc(:ledger, [ledger_index: 'validated']) }.not_to raise_error }
      it { expect(subject.json_rpc(:ledger,  [ledger_index: 'validated']).fetch('ledger_index')).to eq(19352015) }
    end

    context :methodnotfound do
      let(:response_file) do
        File.join('spec', 'resources', 'methodnotfound', 'error.json')
      end

      before do
        stub_request(:post, uri)
          .with(body: { jsonrpc: '2.0',
                        id:      1,
                        method: :methodnotfound,
                        params:  [] }.to_json)
          .to_return(body: response.to_json)
      end

      it do
        expect{ subject.json_rpc(:methodnotfound) }.to \
          raise_error(Peatio::Ripple::Client::ResponseError, "Unknown method. (32)")
      end
    end

    context :notfound do
      let(:response_file) do
        File.join('spec', 'resources', 'methodnotfound', 'error.json')
      end

      before do
        stub_request(:post, uri)
          .with(body: { jsonrpc: '2.0',
                        id:      1,
                        method: :notfound,
                        params:  [] }.to_json)
          .to_return(body: response.to_json, status: 404)
      end

      it do
        expect{ subject.json_rpc(:notfound) }.to \
          raise_error(Peatio::Ripple::Client::Error)
      end
    end

    context :connectionerror do
      before do
        Faraday::Connection.any_instance.expects(:post).raises(Faraday::Error).once
      end

      it do
        expect{ subject.json_rpc(:connectionerror) }.to \
          raise_error(Peatio::Ripple::Client::ConnectionError)
      end
    end
  end
end
