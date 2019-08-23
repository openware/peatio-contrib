# frozen_string_literal: true

require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "peatio"

module Peatio
  module Dash
    require "bigdecimal"
    require "bigdecimal/util"

    require "peatio/dash/blockchain"
    require "peatio/dash/client"
    require "peatio/dash/wallet"

    require "peatio/dash/hooks"

    require "peatio/dash/version"
  end
end
