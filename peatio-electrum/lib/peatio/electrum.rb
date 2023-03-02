# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/enumerable'
require 'peatio'
require 'faraday'
require 'json'

module Peatio
  module Electrum
    Error = Class.new(StandardError)

    require 'peatio/electrum/version'
    require 'peatio/electrum/client'
    require 'peatio/electrum/blockchain'
    require 'peatio/electrum/wallet'
    require 'peatio/electrum/hooks'
  end
end
