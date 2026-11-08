class Assignment < ApplicationRecord
  include AASM
  has_paper_trail

  STATUS_LABELS = { "offered" => "Offered", "accepted" => "Accepted", "rejected" => "Rejected", "expired" => "Expired",
                    "in_production" => "In production", "ready" => "Ready", "dispatched" => "Dispatched", "delivered" => "Delivered" }.freeze
  LIVE = %w[offered accepted in_production ready dispatched delivered].freeze

  belongs_to :booking
  belongs_to :vendor
  belongs_to :vendor_offer
  has_many :recipients, class_name: "BookingRecipient", dependent: :nullify
  has_one :capacity_reservation, dependent: :destroy
  has_many :payouts, class_name: "VendorPayout", dependent: :restrict_with_error
  has_many_attached :qc_photos
  has_many_attached :delivery_proofs

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :mode, inclusion: { in: %w[auto manual] }

  scope :live, -> { where(status: LIVE) }
  scope :sla_breached, -> { where(status: "offered").where(expires_at: ...Time.current) }

  aasm column: :status, whiny_persistence: true, create_scopes: false do
    state :offered, initial: true
    state :accepted, :rejected, :expired, :in_production, :ready, :dispatched, :delivered

    after_all_events :queue_notification

    event :accept do
      transitions from: :offered, to: :accepted, guard: -> { expires_at.nil? || expires_at.future? }
      before { self.accepted_at = Time.current }
    end
    event :reject do
      transitions from: :offered, to: :rejected, guard: -> { rejection_reason.present? }
    end
    event(:expire) { transitions from: :offered, to: :expired }
    event(:start_production) { transitions from: :accepted, to: :in_production }
    event(:mark_ready) { transitions from: :in_production, to: :ready }
    event :mark_dispatched do
      transitions from: :ready, to: :dispatched, guard: -> { recipients.where(awb: [ nil, "" ]).none? }
      before { self.dispatched_at = Time.current }
    end
    event :mark_delivered do
      transitions from: :dispatched, to: :delivered, guard: -> { recipients.where.not(status: "delivered").none? }
      before { self.delivered_at = Time.current }
    end
  end

  def status_label = STATUS_LABELS.fetch(status, status.humanize)
  def live? = LIVE.include?(status)
  def recipients_visible_to_vendor? = !%w[offered rejected expired].include?(status)
  def sla_remaining = expires_at && (expires_at - Time.current)
  def advance_paise = (vendor_total_paise * advance_pct / 100.0).round

  private


  # Notifications fire only after the surrounding transaction commits.
  def queue_notification
    AfterCommitEverywhere.after_commit { AssignmentNotifier.call(self) }
  end
end
