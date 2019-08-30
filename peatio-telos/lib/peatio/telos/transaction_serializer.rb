# frozen_string_literal: true

module Peatio
  module Telos
    class TransactionSerializer
      class << self
        def to_pack_json(address: "default", to_address: "default", amount: "default")
          {
            "code" => "eosio.token",
            "action" => "transfer",
            "args" => {
              "from" => address,
              "to" => to_address,
              "quantity" => amount,
              "memo" => "transfer from peatio"
            }
          }
        end
      end

      class << self
        def to_sign_json(ref_block_num: 2, block_prefix: 1, expiration: "default",
                         address: "default", packed_data: "default", secret: "default", chain_id: "default")
          [
            {
              "ref_block_num" => ref_block_num,
              "ref_block_prefix" => block_prefix,
              "max_cpu_usage_ms" => 0,
              "max_net_usage_words" => 0,
              "expiration" => expiration,
              "region" => "0",
              "actions" => [{
                "account" => "eosio.token",
                  "name" => "transfer",
                  "authorization" => [{
                    "actor" => address,
                      "permission" => "active",
                  }],
                  "data" => packed_data,
              }],
                :signatures => []
            },
            [secret],
            chain_id
          ]
        end
      end

      class << self
        def to_push_json(address: "default", packed_data: "default", expiration: "default",
                         block_num: 2, block_prefix: 1, signature: "default")
          {
            "compression" => "none",
            "transaction" => {
              "actions" => [{
                "account" => "eosio.token",
                "name" => "transfer",
                "authorization" => [{
                  "actor" => address,
                  "permission" => "active"
                }],
                "data" =>  packed_data,
              }],
                "expiration" => expiration,
                "max_cpu_usage_ms" => 0,
                "max_net_usage_words" => 0,
                "delay_sec" => 0,
                "ref_block_num" => block_num,
                "ref_block_prefix" => block_prefix,
                "context_free_actions" => [],
                "context_free_data" => [],
                "signatures" => signature,
                "transaction_extensions" => []
            },
            "signatures" => signature
          }
        end
      end
    end
  end
end
