class Company < ApplicationRecord
  has_paper_trail
  PAYMENT_TERMS = %w[prepaid credit].freeze
  ASSIGNMENT_MODES = %w[auto manual].freeze

  has_many :users, dependent: :restrict_with_error
  has_many :leads, dependent: :nullify
  has_many :employees, dependent: :destroy
  has_many :bookings, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :tickets, dependent: :restrict_with_error

  validates :legal_name, presence: true, length: { maximum: 200 }
  validates :payment_terms, inclusion: { in: PAYMENT_TERMS }
  validates :assignment_mode_override, inclusion: { in: ASSIGNMENT_MODES }, allow_blank: true
  validates :gstin, format: { with: Gstin::FORMAT, message: "is not a valid GSTIN" }, uniqueness: true, allow_blank: true
  validates :pan, format: { with: /\A[A-Z]{5}[0-9]{4}[A-Z]\z/, message: "is not a valid PAN" }, allow_blank: true
  validates :markup_override_pct, numericality: { greater_than_or_equal_to: 0, less_than: 500 }, allow_nil: true

  normalizes :gstin, :pan, with: ->(v) { v.to_s.strip.upcase.presence }

  scope :active, -> { where(active: true) }

  def name = display_name.presence || legal_name
  def credit? = payment_terms == "credit"
  def hr_admins = users.active.where(role: "hr_admin")
  def assignment_mode = assignment_mode_override.presence || Setting[:assignment_mode]
end
