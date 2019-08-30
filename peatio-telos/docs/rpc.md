# RPC Calls

The next list of RPC calls where used for plugin development.
For response examples see spec/resources:

  * /v1/chain/get_info
    `curl http://127.0.0.1:8888/v1/chain/get_info`

  * /v1/chain/get_block
    `curl  -X POST -d '{"block_num_or_id": <needed_block_num>}' http://127.0.0.1:8888/v1/chain/get_block`

  * /v1/chain/get_currency_balance
    `curl  -X POST -d '{"account": "<your_accont_name>", "code": "telosio.token"}' http://127.0.0.1:8888/v1/chain/get_currency_balance`

The next three calls where used to push transaction, for this calls you need to pass json with params which are needed for successfull creation of transaction
Example of such json's can be found in lib/peatio/telos/transaction_json.rb  

  * /v1/chain/abi_json_to_bin
    `curl  -X POST -d @<json_file_with_info_which_you_need_to_encode> http://127.0.0.1:8888/v1/chain/abi_json_to_bin`
    

  **Sign transaction call goes to _/wallet_ route because [ktelosd](https://developers.telos.io/telosio-nodtelos/v1.2.0/docs/ktelosd-overview) handle everything related to wallets, by default ktelosd is running on port 8900**

  * /v1/wallet/sign_transaction
    `curl  -X POST -d @<json_file_with_transaction_which_you_need_to_sign> http://127.0.0.1:8900/v1/wallet/sign_transaction`
  
  * /v1/chain/push_transaction
    `curl  -X POST -d @<json_file_with_signed_transaction_to_push> http://127.0.0.1:8888/v1/chain/push_transaction`
