# JSON RPC

The next list of JSON RPC calls where used for plugin development.
For response examples see spec/resources:

  * getbalance
  
    `curl  --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getbalance", "params": [] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332`
  * getblock
  
    `curl  --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblock", "params": ["5a471d4fd13d8bc3351e4d3a618fa55993326014b925346d8e9272e271e97c4e", 2] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332`
  * getblockcount
  
    `curl  --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockcount", "params": [] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332`
  * getblockhash
  
    `curl --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockhash", "params": [40500] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332 `
  * getnewaddress
  
    `curl --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getnewaddress", "params": [] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332 `
  * listaddressgroupings
  
    `curl --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "listaddressgroupings", "params": [] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332`
  * sendtoaddress
  
    `curl --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "sendtoaddress", "params": ["QRnrwkUBQ2E4ZJ3bj8jvn4Nwx4nJ2U7wXF", 0.11] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332`
  * methodnotfound
  
    `curl  --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "methodnotfound", "params": [] }' -H 'content-type: text/plain;' http://user:password@127.0.0.1:19332`
