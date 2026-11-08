class Payment < ApplicationRecord
  include AASM
  has_paper_trail
  METHODS = { "razorpay" => "Razorpay (online)", "bank_transfer" => "Bank transfer / NEFT", "purchase_order" => "Purchase order" }.freeze

  belongs_to :booking
  belongs_to :verified_by, class_name: "User", optional: true
  has_one_attached :proof

  validates :method, inclusion: { in: METHODS.keys }
  validates :amount_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :gateway_fee_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }

  aasm column: :status, whiny_persistence: true, create_scopes: false do
    state :pending, initial: true
    state :verified, :failed, :refunded

    event :verify do
      transitions from: :pending, to: :verified
      before { self.verified_at = Time.current }
    end
    event :fail do
      transitions from: :pending, to: :failed
    end
    event(:refund) { transitions from: :verified, to: :refunded }
  end

  def method_label = METHODS[method]
  def offline? = method != "razorpay"
end
