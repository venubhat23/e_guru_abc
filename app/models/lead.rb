class Lead < ApplicationRecord
  include AASM
  has_paper_trail

  STATUS_LABELS = {
    "fresh" => "New", "contacted" => "Contacted", "demo_scheduled" => "Demo scheduled",
    "proposal_sent" => "Proposal sent", "won" => "Won", "lost" => "Lost"
  }.freeze
  OPEN_STATES = %i[fresh contacted demo_scheduled proposal_sent].freeze

  belongs_to :occasion, optional: true
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :company, optional: true
  has_many :activities, -> { order(created_at: :desc) }, class_name: "LeadActivity", dependent: :destroy, inverse_of: :lead

  attr_accessor :actor

  normalizes :work_email, with: ->(e) { e.strip.downcase }
  normalizes :name, :company_name, with: ->(v) { v.squish }

  validates :name, :company_name, presence: true, length: { maximum: 150 }
  validates :work_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validate :phone_is_valid
  validates :employee_count, numericality: { only_integer: true, greater_than: 0, less_than: 1_000_000 }, allow_nil: true
  validates :budget_per_employee_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :message, length: { maximum: 3000 }
  validates :consent, acceptance: { accept: true }, on: :create
  validates :lost_reason, presence: true, if: :lost?
  validate :owner_is_platform_user

  scope :recent, -> { order(created_at: :desc) }
  scope :in_pipeline, -> { where(status: OPEN_STATES) }
  scope :follow_up_due, -> { in_pipeline.where(follow_up_on: ..Date.current) }
  scope :search, ->(q) {
    term = "%#{sanitize_sql_like(q.to_s.strip)}%"
    where("leads.name ILIKE :t OR leads.work_email ILIKE :t OR leads.company_name ILIKE :t OR leads.phone ILIKE :t", t: term)
  }

  aasm column: :status, whiny_persistence: true, create_scopes: false do
    state :fresh, initial: true
    state :contacted, :demo_scheduled, :proposal_sent, :won, :lost

    after_all_transitions :log_transition

    event(:mark_contacted) { transitions from: :fresh, to: :contacted }
    event(:schedule_demo) { transitions from: %i[fresh contacted], to: :demo_scheduled }
    event(:send_proposal) { transitions from: %i[fresh contacted demo_scheduled], to: :proposal_sent }
    event(:mark_won) { transitions from: OPEN_STATES, to: :won }
    event :mark_lost do
      transitions from: OPEN_STATES, to: :lost, guard: -> { lost_reason.present? }
    end
    event(:reopen) { transitions from: :lost, to: :contacted, after: -> { self.lost_reason = nil } }
  end

  # Human friendly list of events that are currently allowed, for buttons in the CRM.
  EVENT_LABELS = {
    mark_contacted: "Mark contacted", schedule_demo: "Demo scheduled", send_proposal: "Proposal sent",
    mark_won: "Mark won", mark_lost: "Mark lost", reopen: "Reopen"
  }.freeze

  def status_label = STATUS_LABELS.fetch(status, status.humanize)
  def open? = OPEN_STATES.include?(aasm.current_state)
  def converted? = company_id.present?
  def available_events = aasm.events(permitted: true).map(&:name) | (open? ? [ :mark_lost ] : [])
  def overdue_follow_up? = open? && follow_up_on.present? && follow_up_on < Date.current

  def budget_per_employee_rupees = budget_per_employee_paise && (budget_per_employee_paise / 100)
  def budget_per_employee_rupees=(value)
    self.budget_per_employee_paise = value.presence && (BigDecimal(value.to_s.delete(",")) * 100).round
  rescue ArgumentError
    errors.add(:budget_per_employee_paise, "is not a number")
  end

  def log!(kind, body = nil, user: actor, **metadata)
    activities.create!(kind:, body:, user:, metadata:)
  end

  private

  def log_transition
    from = aasm.from_state
    to = aasm.to_state
    body = "Status changed from #{STATUS_LABELS[from.to_s]} to #{STATUS_LABELS[to.to_s]}"
    body += " — #{lost_reason}" if to == :lost
    # Logged after the record is saved by the bang event
    @pending_transition_log = { body:, from:, to: }
  end

  after_save do
    if (log = @pending_transition_log)
      @pending_transition_log = nil
      log!("status_change", log[:body], from: log[:from], to: log[:to])
    end
  end

  def phone_is_valid
    return if phone.blank?
    errors.add(:phone, "is not a valid phone number") unless Phonelib.valid_for_country?(phone, "IN") || Phonelib.valid?(phone)
  end

  def owner_is_platform_user
    errors.add(:owner, "must be a platform admin") if owner && !owner.platform?
  end
end
