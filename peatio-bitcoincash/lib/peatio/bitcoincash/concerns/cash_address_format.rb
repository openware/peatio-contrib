module CashAddressFormat
  extend ActiveSupport::Concern

  def normalize_address(address)
    CashAddr::Converter.to_cash_address(address)
  end
end
