# frozen_string_literal: true

describe Peatio::Electrum::Blockchain do
  let(:blockchain) { Peatio::Electrum::Blockchain.new }
  let(:uri) { 'http://user:pass@127.0.0.1:7000' }
  let(:currencies) do
    [
      {
        id: :btc,
        options: {}
      },
      {
        id: :usdt,
        options: {}
      }
    ]
  end

  let(:settings) do
    {
      server: uri,
      currencies: currencies
    }
  end

  before(:each) do
    blockchain.configure(settings)
    allow(blockchain.client).to receive(:new_id).and_return(42)
  end

  context :fetch_block! do
    include_context 'mocked electrum server'

    it do
      block = blockchain.fetch_block!(1_723_391)
      expect(block.number).to eq(1_723_391)
      expect(block.transactions).to eq(
        [
          Peatio::Transaction.new(
            amount: 0.01032157.to_d,
            block_number: 1_723_391,
            hash: 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
            status: 'success',
            to_address: '2N6Rt89jaZB1weByMfjYuEeR85r8Gsyn5kG',
            txout: 0,
            currency_id: :btc
          ),
          Peatio::Transaction.new(
            amount: 0.01032157.to_d,
            block_number: 1_723_391,
            hash: 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
            status: 'success',
            to_address: '2N6Rt89jaZB1weByMfjYuEeR85r8Gsyn5kG',
            txout: 0,
            currency_id: :usdt
          ),
          Peatio::Transaction.new(
            amount: 0.001.to_d,
            block_number: 1_723_391,
            hash: 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
            status: 'success',
            to_address: 'mwMVsFVquw2S679z6U72iCJCNXXNbLkVTa',
            txout: 1,
            currency_id: :btc
          ),
          Peatio::Transaction.new(
            amount: 0.001.to_d,
            block_number: 1_723_391,
            hash: 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
            status: 'success',
            to_address: 'mwMVsFVquw2S679z6U72iCJCNXXNbLkVTa',
            txout: 1,
            currency_id: :usdt
          )
        ]
      )
    end

    context 'fetch_block! before electrum is synchronized' do
      it do
        auth_headers = {
          'Authorization' => 'Basic dXNlcjpwYXNz'
        }

        stub_request(:post, 'http://127.0.0.1:7000')
          .with(body: '{"id":42,"method":"is_synchronized","params":[]}')
          .to_return(status: 200, body: '{"result": false, "id": 42, "error": null}', headers: auth_headers)

        expect { expect(blockchain.fetch_block!(123)) }.to raise_error(
          Peatio::Blockchain::ClientError, 'Electrum is synchronizing'
        )
      end
    end
  end
end
