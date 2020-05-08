# frozen_string_literal: true

module Peatio::Electrum::Hooks
  class << self
    def check_compatibility
      if Peatio::Blockchain::VERSION >= '2.0'
        [
          "Electrum plugin was designed for work with 1.x. Blockchain.",
          "You have #{Peatio::Electrum::Blockchain::VERSION}."
        ].join('\n').tap { |s| Kernel.abort s }
      end

      if Peatio::Wallet::VERSION >= '2.0'
        [
          "Electrum plugin was designed for work with 1.x. Wallet.",
          "You have #{Peatio::Electrum::Wallet::VERSION}."
        ].join('\n').tap { |s| Kernel.abort s }
      end
    end

    def register
      Peatio::Blockchain.registry[:Electrum] = Electrum::Blockchain
      Peatio::Wallet.registry[:Electrumd] = Electrum::Wallet
    end
  end

  if defined?(Rails::Railtie)
    require "peatio/Electrum/railtie"
  else
    check_compatibility
    register
  end
end
