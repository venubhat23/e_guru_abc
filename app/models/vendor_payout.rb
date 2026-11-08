class VendorPayout < ApplicationRecord
  include AASM
  has_paper_trail
  KINDS = %w[advance balance].freeze

  belongs_to :vendor
  belongs_to :assignment
  belongs_to :approved_by, class_name: "User", optional: true
  has_one :booking, through: :assignment
  has_one_attached :vendor_invoice

  validates :kind, inclusion: { in: KINDS }
  validates :gross_paise, :amount_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :penalty_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :penalty_within_gross

  scope :outstanding, -> { where(status: %w[due approved]) }
  scope :overdue, -> { outstanding.where(due_on: ...Date.current) }

  aasm column: :status, whiny_persistence: true, create_scopes: false do
    state :due, initial: true
    state :approved, :paid, :received

    after_all_events :queue_notification

    event :approve do
      transitions from: :due, to: :approved, guard: :payable?
      before { self.approved_at = Time.current; self.amount_paise = gross_paise - penalty_paise }
    end
    event :mark_paid do
      transitions from: :approved, to: :paid, guard: -> { utr.present? && payable? }
      before { self.paid_at = Time.current }
    end
    event :mark_received do
      transitions from: :paid, to: :received
      before { self.received_at = Time.current }
    end
  end

  # Note: AASM event `after` callbacks run AFTER the record is saved, so attribute changes
  # belong in `before` (or transition `after:`), which run before persistence.
  # Balance payouts are blocked while the booking is disputed (checked against the DB, not a cached booking).
  def payable? = !(kind == "balance" && Booking.where(id: assignment.booking_id, status: "disputed").exists?)
  def overdue? = (due? || approved?) && due_on < Date.current

  private

  def penalty_within_gross
    errors.add(:penalty_paise, "can't exceed the payout amount") if penalty_paise.to_i > gross_paise.to_i
  end


  # Notifications fire only after the surrounding transaction commits.
  def queue_notification
    AfterCommitEverywhere.after_commit { PayoutNotifier.call(self) }
  end
end
