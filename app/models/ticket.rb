class Ticket < ApplicationRecord
  include AASM
  has_paper_trail
  CATEGORIES = { "damaged" => "Damaged item", "wrong_item" => "Wrong item", "not_delivered" => "Not delivered", "quality" => "Quality issue", "other" => "Other" }.freeze
  PRIORITIES = %w[low normal high urgent].freeze

  belongs_to :booking
  belongs_to :booking_recipient, optional: true
  belongs_to :company
  belongs_to :raised_by, class_name: "User", optional: true
  belongs_to :assignee, class_name: "User", optional: true
  has_many :comments, -> { order(:created_at) }, class_name: "TicketComment", dependent: :destroy, inverse_of: :ticket

  validates :subject, presence: true
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :resolution, presence: true, if: -> { resolved? || closed? }

  before_create { self.number = DocumentSequence.next_number!("ticket").first }

  scope :unresolved, -> { where(status: %w[open in_progress]) }
  scope :recent, -> { order(created_at: :desc) }

  aasm column: :status, whiny_persistence: true, create_scopes: false do
    state :open, initial: true
    state :in_progress, :resolved, :closed
    event(:start) { transitions from: :open, to: :in_progress }
    event :resolve do
      transitions from: %i[open in_progress], to: :resolved, guard: -> { resolution.present? }
      before { self.resolved_at = Time.current }
    end
    event(:close) { transitions from: :resolved, to: :closed }
    event(:reopen) { transitions from: %i[resolved closed], to: :open }
  end

  def category_label = CATEGORIES[category]
end
