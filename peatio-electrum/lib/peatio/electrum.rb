# frozen_string_literal: true

module Peatio
  module Electrum
    Error = Class.new(StandardError)

    require "peatio/electrum/version"
    require "peatio/electrum/hooks"
    require "peatio/electrum/blockchain"
    require "peatio/electrum/wallet"
  end
end

