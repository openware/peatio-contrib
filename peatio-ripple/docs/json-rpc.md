# JSON RPC

The next list of JSON RPC calls where used for plugin development.
For response examples see spec/resources:

  * account_info
    `curl  --data-binary '{"jsonrpc":"2.0","id":1,"method":"fee", "params": [{}]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * fee
    `curl  --data-binary '{"jsonrpc":"2.0","id":1,"method":"ledger", "params": [{ "ledger_index": "validated" }]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * ledger
    `curl  --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockcount", "params": [] }' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * ledger(transaction: true)
    `curl --data-binary '{"jsonrpc":"2.0","id":1,"method":"ledger", "params": [{ "ledger_index": "validated", "transactions": true }]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * sign
    `curl --data-binary '{"jsonrpc":"2.0","id":1,"method":"sign", "params": [{ "secret": "snKAbE6d1wPqeaDai541Wirqq3Pd3", "tx_json": { "Account": "rsFyWHyiDd2bvbnAFPXZnsZyfcQttv4T4c", "Amount": "10000000", "Fee":"10", "Destination": "rB94e2mZZcApwEFeW6oWuME351w1yQpJQy", "TransactionType": "Payment", "LastLedgerSequence": 19697030  } }]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * submit
    `curl --data-binary '{"jsonrpc":"2.0","id":1,"method":"submit", "params": [{ "tx_blob": "12000022800000002400000001201B012C8FC061400000000098968068400000000000000A732102B9C6E7141E6C573B4B458EDA44A1E823C404AA16142C1F26EF714163A3F2FB6E7446304402206796D95E0DF6F0012AE1679B37A2254677E3492CE41261FC23E2BBDBDAF8B93302202C70611478BA8AAB1C7A97C472C9CC9C4A315349CD90C2DDDDD84C95AD938E8381141F02F845784D34EF689AE436709184E69BF17A8883146F46A80656A321D5A1E2224A73DA60C23F218A93" }]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * tx
    `curl --data-binary '{"jsonrpc":"2.0","id":1,"method":"tx", "params": [{ "transaction": "70C40F4A172051B786E954ADE38080311BEE81C788B4257C67F1DBCB7D487F24" }]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * wallet_propose
    `curl --data-binary '{"jsonrpc":"2.0","id":1,"method":"wallet_propose", "params": [{ "key_type": "secp256k1"}]}' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`

  * methodnotfound
    `curl  --data-binary '{"jsonrpc": "2.0", "id": 1, "method": "methodnotfound", "params": [] }' -H 'Content-Type: application/json' http://user:password@127.0.0.1:5005`
