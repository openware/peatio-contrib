module Peatio
  module Bitgo
    class Wallet < Peatio::Wallet::Abstract

      def initialize(settings = {})
        @settings = settings
      end

      def configure(settings = {})
        # Clean client state during configure.
        @client = nil

        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

        @wallet = @settings.fetch(:wallet) do
          raise Peatio::Wallet::MissingSettingError, :wallet
        end.slice(:uri, :address)

        @currency = @settings.fetch(:currency) do
          raise Peatio::Wallet::MissingSettingError, :currency
        end.slice(:id, :base_factor, :options)
      end
    end
  end
end
