require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/string/inquiry"
require "peatio"

module Peatio
  module Bitcoincash
    require "bigdecimal"
    require "bigdecimal/util"
    require "cash_addr"

    require "peatio/bitcoincash/concerns/cash_address_format"

    require "peatio/bitcoincash/blockchain"
    require "peatio/bitcoincash/client"
    require "peatio/bitcoincash/wallet"

    require "peatio/bitcoincash/hooks"

    require "peatio/bitcoincash/version"
  end
end
