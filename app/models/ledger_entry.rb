class LedgerEntry < ApplicationRecord
  ACCOUNTS = %w[revenue marketing_reserve gateway_fees].freeze
  belongs_to :booking
  validates :account, inclusion: { in: ACCOUNTS }, uniqueness: { scope: :booking_id }
  validates :amount_paise, numericality: { only_integer: true }
end
