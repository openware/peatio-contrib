module Peatio
  module Ripple
    module Hooks
      class << self
        def check_compatibility
          if Peatio::Blockchain::VERSION >= '2.0'
            [
              "Ripple plugin was designed for work with 1.x. Blockchain.",
              "You have #{Peatio::Ripple::Blockchain::VERSION}."
            ].join('\n').tap { |s| Kernel.abort s }
          end

          if Peatio::Wallet::VERSION >= '2.0'
            [
              "Ripple plugin was designed for work with 1.x. Wallet.",
              "You have #{Peatio::Ripple::Wallet::VERSION}."
            ].join('\n').tap { |s| Kernel.abort s }
          end
        end

        def register
          Peatio::Blockchain.registry[:ripple] = Ripple::Blockchain
          Peatio::Wallet.registry[:rippled] = Ripple::Wallet
        end
      end

      if defined?(Rails::Railtie)
        require "peatio/ripple/railtie"
      else
        check_compatibility
        register
      end
    end
  end
end
