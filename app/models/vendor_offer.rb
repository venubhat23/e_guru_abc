class VendorOffer < ApplicationRecord
  has_paper_trail
  BALANCE_TERMS = %w[on_delivery credit].freeze

  belongs_to :vendor
  belongs_to :offerable, polymorphic: true
  has_many :capacity_reservations, dependent: :restrict_with_error
  has_many :assignments, dependent: :restrict_with_error

  validates :vendor_price_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :moq, :capacity_per_week, numericality: { only_integer: true, greater_than: 0 }
  validates :lead_time_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :advance_pct, numericality: { only_integer: true, in: 0..100 }
  validates :balance_terms, inclusion: { in: BALANCE_TERMS }
  validates :credit_days, numericality: { only_integer: true, greater_than: 0 }, if: -> { balance_terms == "credit" }
  validates :offerable_type, inclusion: { in: %w[Product Package] }
  validates :vendor_id, uniqueness: { scope: %i[offerable_type offerable_id], message: "already has an offer for this item" }

  scope :active, -> { where(active: true) }
  scope :from_approved_vendors, -> { joins(:vendor).where(vendors: { status: "approved" }) }

  def vendor_price_rupees = vendor_price_paise && vendor_price_paise / 100.0
  def payment_policy = "#{advance_pct}% advance · #{balance_terms == 'credit' ? "#{credit_days}d credit" : 'balance on delivery'}"
end
