module Peatio
  module Bitcoincash
    module Hooks
      BLOCKCHAIN_VERSION_REQUIREMENT = "~> 1.0.0"
      WALLET_VERSION_REQUIREMENT = "~> 1.0.0"

      class << self
        def check_compatibility
          unless Gem::Requirement.new(BLOCKCHAIN_VERSION_REQUIREMENT)
                                 .satisfied_by?(Gem::Version.new(Peatio::Blockchain::VERSION))
            [
              "Bitcoincash blockchain version requirement was not satisfied by Peatio::Blockchain.",
              "Bitcoincash blockchain requires #{BLOCKCHAIN_VERSION_REQUIREMENT}.",
              "Peatio::Blockchain version is #{Peatio::Blockchain::VERSION}"
            ].join('\n').tap { |s| Kernel.abort s }
          end

          unless Gem::Requirement.new(WALLET_VERSION_REQUIREMENT)
                                 .satisfied_by?(Gem::Version.new(Peatio::Wallet::VERSION))
            [
              "Bitcoincash wallet version requirement was not satisfied by Peatio::Wallet.",
              "Bitcoincash wallet requires #{WALLET_VERSION_REQUIREMENT}.",
              "Peatio::Wallet version is #{Peatio::Wallet::VERSION}"
            ].join('\n').tap { |s| Kernel.abort s }
          end
        end

        def register
          Peatio::Blockchain.registry[:bitcoincash] = Bitcoincash::Blockchain
          Peatio::Wallet.registry[:bitcoincashd] = Bitcoincash::Wallet
        end
      end

      if defined?(Rails::Railtie)
        require "peatio/bitcoincash/railtie"
      else
        check_compatibility
        register
      end
    end
  end
end
