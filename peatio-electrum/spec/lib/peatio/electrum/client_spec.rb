# frozen_string_literal: true

describe Peatio::Electrum::Client do
  let(:wallet_url) { 'http://user:pass@127.0.0.1:7000' }
  let(:client) { Peatio::Electrum::Client.new(wallet_url) }
  include_context 'mocked electrum server'

  before(:each) do
    allow(client).to receive(:new_id).and_return(42)
  end

  context 'get_balance' do
    it do
      expect(client.get_balance).to eq('0.011'.to_d)
    end

    it 'fails' do
      expect { client.call('getbalance', ['poney']) }.to raise_error(
        Peatio::Electrum::Client::ResponseError,
        'Invalid parameters: getbalance() takes 1 positional argument but 2 were given (-32602)'
      )
    end
  end

  context 'is_synchronized' do
    it do
      expect(client.is_synchronized).to eq(true)
    end
  end

  context 'get_address_balance' do
    it do
      expect(client.get_address_balance('yRXYPo6Kvhv81TecNvKUx8oJyihL5vLDXc')).to eq(
        {
          'confirmed' => 1.1818.to_d,
          'unconfirmed' => 0.to_d
        }
      )
    end
  end

  context 'get_local_height' do
    it do
      expect(client.get_local_height).to eq(305_062)
    end
  end

  context 'create_address' do
    it do
      expect(client.create_address).to eq('miACDRY1sVVmznApZv1sSkQXZyhAHNcKHW')
    end
  end

  context 'list_unspent' do
    it do
      expect(client.list_unspent).to eq(
        [
          {
            'address' => 'n3eDkbbRN8wQECdTcfSvFPRbHW5f9BEJP7',
            'value' => '0.01',
            'prevout_n' => 0,
            'prevout_hash' => 'a6840a8ea7e6f713ca8493dd0d59169b812dc775c90d3ff599c7782eb6cb3a27',
            'height' => 1_723_446,
            'coinbase' => false
          },
          {
            'address' => 'mwMVsFVquw2S679z6U72iCJCNXXNbLkVTa',
            'value' => '0.001',
            'prevout_n' => 1,
            'prevout_hash' => 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
            'height' => 1_723_391,
            'coinbase' => false
          },
          {
            'address' => 'mquxiWbT1Nqdt3wbwzEnMvDFrrP5heHkdB',
            'value' => '0.01',
            'prevout_n' => 0,
            'prevout_hash' => 'eff4a1aa963e70812272b4b48ab144f87a2789de7dba5290a723950c1fc2ef76',
            'height' => 1_723_456,
            'coinbase' => false
          }
        ]
      )
    end
  end

  context 'history' do
    it do
      expect(client.history).to eq(
        {
          'summary' =>
          {
            'end_balance' => '0.021',
            'end_date' => nil,
            'from_height' => nil,
            'incoming' => '0.021',
            'outgoing' => '0.',
            'start_balance' => '0.',
            'start_date' => nil,
            'to_height' => nil
          },
          'transactions' => [
            {
              'balance' => '0.001',
              'confirmations' => 117,
              'date' => '2020-05-08 23:42',
              'fee' => '0.00000168',
              'height' => 1_723_391,
              'incoming' => true,
              'inputs' => [
                {
                  'prevout_hash' => '8f4bf6e4cd722098e9f2a1bdb60188c9d63e9b567c1008fd447528258b37f764',
                  'prevout_n' => 1
                }
              ],
              'label' => '',
              'outputs' => [
                {
                  'address' => '2N6Rt89jaZB1weByMfjYuEeR85r8Gsyn5kG',
                  'value' => '0.01032157'
                },
                {
                  'address' => 'mwMVsFVquw2S679z6U72iCJCNXXNbLkVTa',
                  'value' => '0.001'
                }
              ],
              'timestamp' => 1_588_970_574,
              'txid' => 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
              'txpos_in_block' => 138,
              'value' => '0.001'
            },
            { 'balance' => '0.011',
              'confirmations' => 62,
              'date' => '2020-05-09 11:07',
              'fee' => nil,
              'height' => 1_723_446,
              'incoming' => true,
              'inputs' => [
                {
                  'prevout_hash' => 'aa86ad5544a29664e16393e949812862a7e16daad6f43962563364515383cedf',
                  'prevout_n' => 1
                }
              ],
              'label' => '',
              'outputs' => [
                {
                  'address' => 'n3eDkbbRN8wQECdTcfSvFPRbHW5f9BEJP7',
                  'value' => '0.01'
                },
                {
                  'address' => '2N5YiTFok4xhN1eM3hbfbzPU5qFuXcufq11',
                  'value' => '0.06199666'
                }
              ],
              'timestamp' => 1_589_011_647,
              'txid' => 'a6840a8ea7e6f713ca8493dd0d59169b812dc775c90d3ff599c7782eb6cb3a27',
              'txpos_in_block' => 72,
              'value' => '0.01' },
            {
              'balance' => '0.021',
              'confirmations' => 52,
              'date' => '2020-05-09 13:32',
              'fee' => '0.00000168',
              'height' => 1_723_456,
              'incoming' => true,
              'inputs' => [
                {
                  'prevout_hash' => 'ee06a5a9ee9a336d94514b9483460d1e919e082a8f0cf01c462c2322ccb3b0aa',
                  'prevout_n' => 0
                }
              ],
              'label' => '',
              'outputs' => [
                {
                  'address' => 'mquxiWbT1Nqdt3wbwzEnMvDFrrP5heHkdB',
                  'value' => '0.01'
                },
                {
                  'address' => '2N6Ye8Zdg7kVZELMLKAV2WVFtzeQcXDCTw2',
                  'value' => '0.05099359'
                }
              ],
              'timestamp' => 1_589_020_359,
              'txid' => 'eff4a1aa963e70812272b4b48ab144f87a2789de7dba5290a723950c1fc2ef76',
              'txpos_in_block' => 131,
              'value' => '0.01'
            }
          ]
        }
      )
    end

    it do
      expect(client.history(nil, true, false, true, 1_723_391, 1_723_392)).to eq(
        {
          'summary' =>
          {
            'end_balance' => '0.021',
            'end_date' => nil,
            'from_height' => nil,
            'incoming' => '0.021',
            'outgoing' => '0.',
            'start_balance' => '0.',
            'start_date' => nil,
            'to_height' => nil
          },
          'transactions' => [
            {
              'balance' => '0.001',
              'confirmations' => 117,
              'date' => '2020-05-08 23:42',
              'fee' => '0.00000168',
              'height' => 1_723_391,
              'incoming' => true,
              'inputs' => [
                {
                  'prevout_hash' => '8f4bf6e4cd722098e9f2a1bdb60188c9d63e9b567c1008fd447528258b37f764',
                  'prevout_n' => 1
                }
              ],
              'label' => '',
              'outputs' => [
                {
                  'address' => '2N6Rt89jaZB1weByMfjYuEeR85r8Gsyn5kG',
                  'value' => '0.01032157'
                },
                {
                  'address' => 'mwMVsFVquw2S679z6U72iCJCNXXNbLkVTa',
                  'value' => '0.001'
                }
              ],
              'timestamp' => 1_588_970_574,
              'txid' => 'd0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89',
              'txpos_in_block' => 138,
              'value' => '0.001'
            }
          ]
        }
      )
    end
  end

  context 'get_tx_status' do
    it do
      expect(client.get_tx_status('d0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89')).to eq('confirmations' => 58)
    end
  end

  context 'get_transaction' do
    it do
      expect(client.get_transaction('d0c37ddc9f02426307c161e6f486bb547606f57cfebea6daac8d138828a32c89')).to eq(
        'hex' => '0200000000010164f7378b25287544fd08107c569b3ed6c98801b6bda1f2e9982072cde4f64b8f0100000017160014e26a9cb4accfa5d0ed0195b1a2e2693aa72b3875feffffff02ddbf0f000000000017a914909da0fbb7c1d0947181e2fc9b7e11a2052c150387a0860100000000001976a914adb8354c90d2a5c50bf5b6c786618bc9d1d5f66588ac02473044022035b4e88ff0d5b41d842ddf75a707e2e5e081b445ec6103038a8c4315f7848bfa02201f6182de6d4c40d925f3063e462f5e694b9f52d7103d39365985e95536dcf991012103f600b692c1170c8cf46aeae0c60a3d80447e8e70a0281c56a21aa7097abbd460fe4b1a00',
        'complete' => true,
        'final' => true
      )
    end
  end

  context 'payto' do
    it do
      expect(client.payto('mkHS9ne12qx9pS9VojpwU5xtRd4T7X7ZUt', 0.001)).to eq(
        'hex' => '0200000001273acbb62e78c799f53f0dc975c72d819b16590ddd9384ca13f7e6a78e0a84a6000000006b483045022100dc701ee09e0851c62ab8bccf4bd803d2aeef2a2c53d18e082b6cb1658ba1ccdb022003f1cdfca0d1f3019a9ba5fdbdae9e037a81e55dfd9cbe2d92ffbe4123faf85c0121031e80dfe90863c16369970daab2cbdcd9e458323cab63e5fba8ccb8a64c8dc672fdffffff02a0860100000000001976a914344a0f48ca150ec2b903817660b9b68b13a6702688acbeba0d00000000001976a914de832435d134b2119b2fdeb2cb80b20d9a805a6088acc94c1a00',
        'complete' => true,
        'final' => false
      )
    end
  end

  context 'broadcast' do
    it do
      expect(client.broadcast('0200000001273acbb62e78c799f53f0dc975c72d819b16590ddd9384ca13f7e6a78e0a84a6000000006b483045022100dc701ee09e0851c62ab8bccf4bd803d2aeef2a2c53d18e082b6cb1658ba1ccdb022003f1cdfca0d1f3019a9ba5fdbdae9e037a81e55dfd9cbe2d92ffbe4123faf85c0121031e80dfe90863c16369970daab2cbdcd9e458323cab63e5fba8ccb8a64c8dc672fdffffff02a0860100000000001976a914344a0f48ca150ec2b903817660b9b68b13a6702688acbeba0d00000000001976a914de832435d134b2119b2fdeb2cb80b20d9a805a6088acc94c1a00')).to eq(
        '79e98ec6cb4952906d8b119dec4224e47fc9b0731e08f6a8a2209853b7930ce4'
      )
    end
  end
end
