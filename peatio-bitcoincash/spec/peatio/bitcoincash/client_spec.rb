RSpec.describe Peatio::Bitcoincash::Client do
  let(:uri) { "http://user:password@127.0.0.1:18332" }
  let(:uri_without_authority) { "http://127.0.0.1:18332" }

  before(:all) { WebMock.disable_net_connect! }
  after(:all) { WebMock.allow_net_connect! }

  subject { Peatio::Bitcoincash::Client.new(uri) }

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
        File.join('spec', 'resources', 'getblockcount', '1304026.json')
      end

      before do
        stub_request(:post, uri_without_authority)
          .with(body: { jsonrpc: '1.0',
                        method: :getblockcount,
                        params:  [] }.to_json)
          .to_return(body: response.to_json)
      end

      it { expect{ subject.json_rpc(:getblockcount) }.not_to raise_error }
      it { expect(subject.json_rpc(:getblockcount)).to eq(1304026) }
    end

    context :methodnotfound do
      let(:response_file) do
        File.join('spec', 'resources', 'methodnotfound', 'error.json')
      end

      before do
        stub_request(:post, uri_without_authority)
          .with(body: { jsonrpc: '1.0',
                        method: :methodnotfound,
                        params:  [] }.to_json)
          .to_return(body: response.to_json)
      end

      it do
        expect{ subject.json_rpc(:methodnotfound) }.to \
          raise_error(Peatio::Bitcoincash::Client::ResponseError, "Method not found (-32601)")
      end
    end

    context :notfound do
      let(:response_file) do
        File.join('spec', 'resources', 'methodnotfound', 'error.json')
      end

      before do
        stub_request(:post, uri_without_authority)
          .with(body: { jsonrpc: '1.0',
                        method: :notfound,
                        params:  [] }.to_json)
          .to_return(body: response.to_json, status: 404)
      end

      it do
        expect{ subject.json_rpc(:notfound) }.to \
          raise_error(Peatio::Bitcoincash::Client::Error)
      end
    end

    context :connectionerror do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::Error.new("Something went wrong"))
      end

      it do
        expect{ subject.json_rpc(:connectionerror) }.to \
          raise_error(Peatio::Bitcoincash::Client::ConnectionError)
      end
    end
  end
end
