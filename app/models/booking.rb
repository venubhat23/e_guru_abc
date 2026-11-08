class Booking < ApplicationRecord
  include AASM
  has_paper_trail

  DELIVERY_MODES = { "individual" => "Individual home addresses", "bulk_office" => "Bulk to office", "self_fill" => "Employee self-fill link" }.freeze
  STATUS_LABELS = {
    "draft" => "Draft", "pending_approval" => "Pending approval", "awaiting_payment" => "Awaiting payment", "paid" => "Paid",
    "assigning" => "Assigning", "assigned" => "Assigned", "confirmed" => "Confirmed", "in_fulfilment" => "In fulfilment",
    "partially_dispatched" => "Partially dispatched", "dispatched" => "Dispatched", "delivered" => "Delivered",
    "completed" => "Completed", "cancelled" => "Cancelled", "disputed" => "Disputed"
  }.freeze
  CANCELLABLE = %i[draft pending_approval awaiting_payment paid assigning assigned].freeze
  COMMITTED = %w[paid assigning assigned confirmed in_fulfilment partially_dispatched dispatched delivered completed disputed].freeze
  OPEN = %w[pending_approval awaiting_payment paid assigning assigned confirmed in_fulfilment partially_dispatched dispatched delivered disputed].freeze

  belongs_to :company
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :occasion, optional: true
  belongs_to :bookable, polymorphic: true
  has_many :recipients, class_name: "BookingRecipient", dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :payments, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :tickets, dependent: :restrict_with_error
  has_many :payouts, through: :assignments

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :delivery_mode, inclusion: { in: DELIVERY_MODES.keys }
  validates :assignment_mode, inclusion: { in: %w[auto manual] }
  validates :requested_delivery_on, :place_of_supply_state, presence: true

  after_create { update_column(:number, format("BK%<y>s%<id>05d", y: created_at.strftime("%y"), id: id)) }

  scope :recent, -> { order(created_at: :desc) }
  scope :committed, -> { where(status: COMMITTED) }

  aasm column: :status, whiny_persistence: true, create_scopes: false do
    state :draft, initial: true
    state :pending_approval, :awaiting_payment, :paid, :assigning, :assigned, :confirmed, :in_fulfilment,
          :partially_dispatched, :dispatched, :delivered, :completed, :cancelled, :disputed

    after_all_transitions :stamp_transition
    after_all_events :queue_notification

    event :submit do
      transitions from: :draft, to: :pending_approval, guard: :needs_approval?
      transitions from: :draft, to: :assigning, guard: -> { company.credit? }
      transitions from: :draft, to: :awaiting_payment
    end
    event :approve do
      transitions from: :pending_approval, to: :assigning, guard: -> { company.credit? }
      transitions from: :pending_approval, to: :awaiting_payment
    end
    event(:mark_paid) { transitions from: :awaiting_payment, to: :paid }
    event(:start_assigning) { transitions from: :paid, to: :assigning }
    event(:mark_assigned) { transitions from: :assigning, to: :assigned, guard: :fully_assigned? }
    event(:return_to_assigning) { transitions from: %i[assigned assigning], to: :assigning }
    event(:confirm) { transitions from: :assigned, to: :confirmed, guard: :all_assignments_accepted? }
    event(:start_fulfilment) { transitions from: :confirmed, to: :in_fulfilment }
    event(:partially_dispatch) { transitions from: :in_fulfilment, to: :partially_dispatched }
    event(:mark_dispatched) { transitions from: %i[in_fulfilment partially_dispatched], to: :dispatched, guard: :all_dispatched? }
    event(:mark_delivered) { transitions from: %i[dispatched disputed], to: :delivered, guard: :all_delivered? }
    event(:complete) { transitions from: :delivered, to: :completed, guard: :all_payouts_received? }
    event :cancel do
      transitions from: CANCELLABLE, to: :cancelled, guard: -> { cancel_reason.present? }
    end
    event :dispute do
      transitions from: %i[in_fulfilment partially_dispatched dispatched delivered], to: :disputed, guard: -> { dispute_reason.present? }
    end
  end

  def to_param = number.presence || id.to_s
  def status_label = STATUS_LABELS.fetch(status, status.humanize)
  def delivery_mode_label = DELIVERY_MODES[delivery_mode]
  def bookable_name = bookable.try(:name)
  def intra_state? = place_of_supply_state == Setting[:platform_state]
  def gst_paise = cgst_paise + sgst_paise + igst_paise
  def taxable_paise = hr_subtotal_paise + delivery_charge_paise
  def needs_approval? = company.approval_limit_paise.present? && total_paise > company.approval_limit_paise
  def paid_paise = payments.where(status: "verified").sum(:amount_paise)
  def balance_due_paise = [ total_paise - paid_paise, 0 ].max
  def margin_paise = vendor_subtotal_paise.positive? ? hr_subtotal_paise - vendor_subtotal_paise : nil

  def live_assignments = assignments.where.not(status: %w[rejected expired])
  def unassigned_recipients = recipients.where(assignment_id: nil)
  def fully_assigned? = recipients.any? && unassigned_recipients.none?
  def all_assignments_accepted? = live_assignments.any? && live_assignments.where(status: "offered").none?
  def all_dispatched? = recipients.any? && recipients.where.not(status: %w[dispatched delivered]).none?
  def all_delivered? = recipients.any? && recipients.where.not(status: "delivered").none?
  def all_payouts_received? = live_assignments.all? { |a| a.payouts.any? && a.payouts.all?(&:received?) && a.payouts.exists?(kind: "balance") }
  def open_tickets? = tickets.where(status: %w[open in_progress]).exists?
  def last_delivered_at = recipients.maximum(:delivered_at)
  def tax_invoice = invoices.find_by(kind: "tax_invoice")

  def refresh_vendor_subtotal!
    update_column(:vendor_subtotal_paise, live_assignments.sum(:vendor_total_paise))
  end

  private

  def stamp_transition
    stamp = { submitted_at: :submit, paid_at: :mark_paid, confirmed_at: :confirm, delivered_at: :mark_delivered, completed_at: :complete, cancelled_at: :cancel }
    stamp.each { |col, ev| self[col] = Time.current if aasm.current_event.to_s.delete("!") == ev.to_s }
  end


  # Notifications fire only after the surrounding transaction commits.
  def queue_notification
    AfterCommitEverywhere.after_commit { BookingNotifier.call(self) }
  end
end
