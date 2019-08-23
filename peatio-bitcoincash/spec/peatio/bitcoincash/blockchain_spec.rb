RSpec.describe Peatio::Bitcoincash::Blockchain do
  context :features do
    it 'defaults' do
      blockchain1 = Peatio::Bitcoincash::Blockchain.new
      expect(blockchain1.features).to eq Peatio::Bitcoincash::Blockchain::DEFAULT_FEATURES
    end

    it 'override defaults' do
      blockchain2 = Peatio::Bitcoincash::Blockchain.new(cash_addr_format: false)
      expect(blockchain2.features[:cash_addr_format]).to be_falsey
    end

    it 'custom feautures' do
      blockchain3 = Peatio::Bitcoincash::Blockchain.new(custom_feature: :custom)
      expect(blockchain3.features.keys).to contain_exactly(*Peatio::Bitcoincash::Blockchain::SUPPORTED_FEATURES)
    end
  end

  context :configure do
    let(:blockchain) { Peatio::Bitcoincash::Blockchain.new }
    it 'default settings' do
      expect(blockchain.settings).to eq({})
    end

    it 'currencies and server configuration' do
      currencies = [{ id: :bch,
                      base_factor: 100_000_000,
                      options: {} }]
      settings = { server: 'http://user:password@127.0.0.1:18332',
                   currencies: currencies,
                   something: :custom }
      blockchain.configure(settings)
      expect(blockchain.settings).to eq(settings.slice(*Peatio::Blockchain::Abstract::SUPPORTED_SETTINGS))
    end
  end

  context :latest_block_number do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:18332' }
    let(:server_without_authority) { 'http://127.0.0.1:18332' }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'getblockcount', '1304026.json')
    end

    let(:blockchain) do
      Peatio::Bitcoincash::Blockchain.new.tap {|b| b.configure(server: server)}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :getblockcount,
                      params:  [] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'returns latest block number' do
      expect(blockchain.latest_block_number).to eq(1304026)
    end

    it 'raises error if there is error in response body' do
      stub_request(:post, 'http://127.0.0.1:18332')
        .with(body: { jsonrpc: '1.0',
                      method: :getblockcount,
                      params:  [] }.to_json)
        .to_return(body: { result: nil,
                           error:  { code: -32601, message: 'Method not found' },
                           id:     nil }.to_json)

      expect{ blockchain.latest_block_number }.to raise_error(Peatio::Blockchain::ClientError)
    end
  end

  context :build_transaction do

    let(:raw_transaction) do
      {
          "hex" => "0200000021006fb176be9cdf45a8e4864a27bb29f27b0d02645b605ff2cb25e1a72c83809a000000006a473044022031cb70df5885b7cad8d0e9cb91b61d181ed12b3643bf1c7d9979c68b6776204d",
          "txid" => "ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          "hash" => "ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          "vin" => [
              {
                  "txid" => "56a02ff8696ecb22423987167fd18160986d73c5a8354c5413cf1116c6115291",
                  "vout" => 0,
                  "scriptSig" => {
                      "asm" => "3044022013859f9db46d2a84ce495b385ea44d678ae8117719e31db68bd93ed6ff2c147602201b6873b477823d10dd4b621ea3e9374b5e4e7ea57b37bb345905fa98af8a79ba[ALL|FORKID] 02a9a3b6a818a0e1adf83c466ce86df14575849cf3afb59473e6e117184518f161",
                      "hex" => "473044022013859f9db46d2a84ce495b385ea44d678ae8117719e31db68bd93ed6ff2c147602201b6873b477823d10dd4b621ea3e9374b5e4e7ea57b37bb345905fa98af8a79ba412102a9a3b6a818a0e1adf83c466ce86df14575849cf3afb59473e6e117184518f161"
                  },
                  "sequence" => 4294967294
              },
              {
                  "txid" => "c7c71ef59559788e301b674fcf7728942f1e8a17a00803b8c39092ea1cb1a500",
                  "vout" => 0,
                  "scriptSig" => {
                      "asm" => "30440220010e2a54dfe424f29515fac69d0f1dc9042f9615ee01ea8873704313aeb8596b02207598b6344e604012f7f3476d35d064a915148604f4b0bc43a1cca7589b541281[ALL|FORKID] 02d7e096ae8d1ad5fcc71f9effadc7324313d4db37fd3578edfbb7bac18b8239bd",
                      "hex" => "4730440220010e2a54dfe424f29515fac69d0f1dc9042f9615ee01ea8873704313aeb8596b02207598b6344e604012f7f3476d35d064a915148604f4b0bc43a1cca7589b541281412102d7e096ae8d1ad5fcc71f9effadc7324313d4db37fd3578edfbb7bac18b8239bd"
                  },
                  "sequence" => 4294967294
              }
          ],
          "vout" => [
              {
                  "value" => 0.00005673,
                  "n" => 0,
                  "scriptPubKey" => {
                      "asm" => "OP_DUP OP_HASH160 ee3ed37225d569a1bd101950c905bd366c2ef585 OP_EQUALVERIFY OP_CHECKSIG",
                      "hex" => "76a914ee3ed37225d569a1bd101950c905bd366c2ef58588ac",
                      "reqSigs" => 1,
                      "type" => "pubkeyhash",
                      "addresses" => [
                          "bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd"
                      ]
                  }
              },
              {
                  "value" => 0.00001000,
                  "n" => 0,
                  "scriptPubKey" => {
                      "asm" => "OP_DUP OP_HASH160 ee3ed37225d569a1bd101950c905bd366c2ef585 OP_EQUALVERIFY OP_CHECKSIG",
                      "hex" => "76a914ee3ed37225d569a1bd101950c905bd366c2ef58588ac",
                      "reqSigs" => 1,
                      "type" => "pubkeyhash",
                      "addresses" => [
                          "bchtest:qqz36d3t6w5crqc96y762zymryej9gt4s5hmy3wlm0"
                      ]
                  }
              }
          ]
      }
    end

    context 'two vout tx' do
      let(:expected_transactions) do
        [{:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd",
          :amount=>0.00005673.to_d,
          :status=>"success",
          :currency_id=>currency[:id]},
         {:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qqz36d3t6w5crqc96y762zymryej9gt4s5hmy3wlm0",
          :amount=>0.00001000.to_d,
          :status=>"success",
          :currency_id=>currency[:id]}
        ]
      end

      let(:currency) do
        { id: :bch,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:blockchain) do
        Peatio::Bitcoincash::Blockchain.new.tap { |b| b.configure(currencies: [currency]) }
      end

      it 'builds formatted transactions for passed transaction' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context 'multiple currencies' do
      let(:currency1) do
        { id: :bch1,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:currency2) do
        { id: :bch2,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:expected_transactions) do
        [{:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd",
          :amount=>0.00005673.to_d,
          :status=>"success",
          :currency_id=>currency1[:id]},
         {:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd",
          :amount=>0.00005673.to_d,
          :status=>"success",
          :currency_id=>currency2[:id]},
         {:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qqz36d3t6w5crqc96y762zymryej9gt4s5hmy3wlm0",
          :amount=>0.00001000.to_d,
          :status=>"success",
          :currency_id=>currency1[:id]},
         {:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qqz36d3t6w5crqc96y762zymryej9gt4s5hmy3wlm0",
          :amount=>0.00001000.to_d,
          :status=>"success",
          :currency_id=>currency2[:id]}
        ]
      end

      let(:blockchain) do
        Peatio::Bitcoincash::Blockchain.new.tap do |b|
          b.configure(currencies: [currency1, currency2])
        end
      end

      it 'builds formatted transactions for passed transaction per each currency' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context 'single vout transaction' do
      let(:currency) do
        { id: :bch,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:blockchain) do
        Peatio::Bitcoincash::Blockchain.new.tap { |b| b.configure(currencies: [currency]) }
      end

      let(:raw_transaction) do
        {
            "hex" => "0200000021006fb176be9cdf45a8e4864a27bb29f27b0d02645b605ff2cb25e1a72c83809a000000006a473044022031cb70df5885b7cad8d0e9cb91b61d181ed12b3643bf1c7d9979c68b6776204d",
            "txid" => "ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
            "hash" => "ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
            "vin" => [
                {
                    "txid" => "56a02ff8696ecb22423987167fd18160986d73c5a8354c5413cf1116c6115291",
                    "vout" => 0,
                    "scriptSig" => {
                        "asm" => "3044022013859f9db46d2a84ce495b385ea44d678ae8117719e31db68bd93ed6ff2c147602201b6873b477823d10dd4b621ea3e9374b5e4e7ea57b37bb345905fa98af8a79ba[ALL|FORKID] 02a9a3b6a818a0e1adf83c466ce86df14575849cf3afb59473e6e117184518f161",
                        "hex" => "473044022013859f9db46d2a84ce495b385ea44d678ae8117719e31db68bd93ed6ff2c147602201b6873b477823d10dd4b621ea3e9374b5e4e7ea57b37bb345905fa98af8a79ba412102a9a3b6a818a0e1adf83c466ce86df14575849cf3afb59473e6e117184518f161"
                    },
                    "sequence" => 4294967294
                },
                {
                    "txid" => "c7c71ef59559788e301b674fcf7728942f1e8a17a00803b8c39092ea1cb1a500",
                    "vout" => 0,
                    "scriptSig" => {
                        "asm" => "30440220010e2a54dfe424f29515fac69d0f1dc9042f9615ee01ea8873704313aeb8596b02207598b6344e604012f7f3476d35d064a915148604f4b0bc43a1cca7589b541281[ALL|FORKID] 02d7e096ae8d1ad5fcc71f9effadc7324313d4db37fd3578edfbb7bac18b8239bd",
                        "hex" => "4730440220010e2a54dfe424f29515fac69d0f1dc9042f9615ee01ea8873704313aeb8596b02207598b6344e604012f7f3476d35d064a915148604f4b0bc43a1cca7589b541281412102d7e096ae8d1ad5fcc71f9effadc7324313d4db37fd3578edfbb7bac18b8239bd"
                    },
                    "sequence" => 4294967294
                }
            ],
            "vout" => [
                {
                    "value" => 0.00005673,
                    "n" => 0,
                    "scriptPubKey" => {
                        "asm" => "OP_DUP OP_HASH160 ee3ed37225d569a1bd101950c905bd366c2ef585 OP_EQUALVERIFY OP_CHECKSIG",
                        "hex" => "76a914ee3ed37225d569a1bd101950c905bd366c2ef58588ac",
                        "reqSigs" => 1,
                        "type" => "pubkeyhash",
                        "addresses" => [
                            "bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd"
                        ]
                    }
                }
            ]
        }
      end

      let(:expected_transactions) do
        [{:hash=>"ee8519e72f4a49da44197cbf417bfe9e00f1c2d0f3db930df94e4e50391ea3fd",
          :txout=>0,
          :to_address=>"bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd",
          :amount=>0.00005673.to_d,
          :status=>"success",
          :currency_id=>currency[:id]}]
      end

      it 'builds formatted transactions for each vout' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end
  end

  context :fetch_block! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:18332' }
    let(:server_without_authority) { 'http://127.0.0.1:18332' }

    let(:getblockhash_response_file) do
      File.join('spec', 'resources', 'getblockhash', '1304026.json')
    end

    let(:getblockhash_response) do
      getblockhash_response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:getblock_response_file) do
      File.join('spec', 'resources', 'getblock', '1304026.json')
    end

    let(:getblock_response) do
      getblock_response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:getrawtransaction_response_file) do
      File.join('spec', 'resources', 'getrawtransaction', 'response.json')
    end

    let(:getrawtransaction_response) do
      getrawtransaction_response_file
          .yield_self { |file_path| File.open(file_path) }
          .yield_self { |file| JSON.load(file) }
    end

    let(:blockchain) do
      Peatio::Bitcoincash::Blockchain.new.tap {|b| b.configure(server: server)}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :getblockhash,
                      params:  [1304026] }.to_json)
        .to_return(body: getblockhash_response.to_json)

      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :getblock,
                      params:  ['0000000071e7ee4a062598c576c818e3f0fba7edd0191d966041680bf7a0d2b1',true] }.to_json)
        .to_return(body: getblock_response.to_json)

      stub_request(:post, server_without_authority)
          .with(body: { jsonrpc: '1.0',
                        method: :getrawtransaction,
                        params:  ['68073517bbcd388ee73fb9a078d04418596b84b4c57f3997280a0a3e7dcfa150',true] }.to_json)
          .to_return(body: getrawtransaction_response.to_json)
    end

    let(:currency) do
      { id: :bch,
        base_factor: 100_000_000,
        options: {} }
    end

    let(:server) { 'http://user:password@127.0.0.1:18332' }
    let(:server_without_authority) { 'http://127.0.0.1:18332' }
    let(:blockchain) do
      Peatio::Bitcoincash::Blockchain.new.tap { |b| b.configure(server: server, currencies: [currency]) }
    end

    subject { blockchain.fetch_block!(1304026) }

    it 'builds expected number of transactions' do
      expect(subject.count).to eq(2)
    end

    it 'all transactions are valid' do
      expect([subject.all?(&:valid?)]).to be_truthy
    end
  end

  context :load_balance_of_address! do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:18332' }
    let(:server_without_authority) { 'http://127.0.0.1:18332' }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'listaddressgroupings', 'response.json')
    end

    let(:blockchain) do
      Peatio::Bitcoincash::Blockchain.new.tap {|b| b.configure(server: server)}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :listaddressgroupings,
                      params:  [] }.to_json)
        .to_return(body: response.to_json)
    end

    context 'address with balance is defined' do
      it 'requests rpc listaddressgroupings and finds address balance' do
        address = 'bchtest:qrhra5mjyh2kngdazqv4pjg9h5mxcth4s5jfez39qd'

        result = blockchain.load_balance_of_address!(address, :bch)
        expect(result).to be_a(BigDecimal)
        expect(result).to eq('0.00005673'.to_d)
      end

      it 'requests rpc listaddressgroupings and finds address with zero balance' do
        address = 'bchtest:qqz36d3t6w5crqc96y762zymryej9gt4s5hmy3wlm0'

        result = blockchain.load_balance_of_address!(address, :bch)
        expect(result).to be_a(BigDecimal)
        expect(result).to eq('0'.to_d)
      end
    end

    context 'address is not defined' do
      it 'requests rpc listaddressgroupings and do not find address' do
        address = 'bchtest:pp49pee25hv4esy7ercslnvnvxqvk5gjdv5a06mg35'
        expect{ blockchain.load_balance_of_address!(address, :bch)}.to raise_error(Peatio::Blockchain::UnavailableAddressBalanceError)
      end
    end

    context 'client error is raised' do
      before do
        stub_request(:post, 'http://127.0.0.1:18332')
          .with(body: { jsonrpc: '1.0',
                        method: :listaddressgroupings,
                        params: [] }.to_json)
          .to_return(body: { result: nil,
                             error:  { code: -32601, message: 'Method not found' },
                             id:     nil }.to_json)
      end

      it 'raise wrapped client error' do
        expect{ blockchain.load_balance_of_address!('anything', :bch)}.to raise_error(Peatio::Blockchain::ClientError)
      end
    end
  end
end
