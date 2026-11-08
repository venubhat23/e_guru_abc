class User < ApplicationRecord
  has_paper_trail ignore: %i[password_digest last_sign_in_at updated_at]

  PLATFORM_ROLES = %w[super_admin ops_admin finance_admin].freeze
  HR_ROLES       = %w[hr_admin hr_member].freeze
  VENDOR_ROLES   = %w[vendor_owner vendor_staff].freeze
  ROLES          = (PLATFORM_ROLES + HR_ROLES + VENDOR_ROLES).freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :owned_leads, class_name: "Lead", foreign_key: :owner_id, dependent: :nullify, inverse_of: :owner
  belongs_to :company, optional: true
  belongs_to :vendor, optional: true

  enum :role, ROLES.index_with(&:itself), validate: true

  generates_token_for :email_verification, expires_in: 2.days do
    email_address
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 120 }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :company, presence: true, if: :hr?
  validates :vendor, presence: true, if: :vendor_user?
  validate :tenant_matches_role

  scope :active, -> { where(active: true) }
  scope :platform, -> { where(role: PLATFORM_ROLES) }
  scope :ordered, -> { order(:name) }

  def platform? = PLATFORM_ROLES.include?(role)
  def hr? = HR_ROLES.include?(role)
  def vendor_user? = VENDOR_ROLES.include?(role)
  def email_verified? = email_verified_at.present?
  def verify_email! = update!(email_verified_at: Time.current)
  def initials = name.to_s.split.first(2).map { _1[0] }.join.upcase
  def first_name = name.to_s.split.first

  def portal
    return :admin if platform?
    return :hr if hr?
    :vendor
  end

  def role_label = role.to_s.humanize.sub(/\AHr /, "HR ").sub(/\AOps /, "Ops ")

  private

  def tenant_matches_role
    errors.add(:company, "must be blank for this role") if company.present? && !hr?
    errors.add(:vendor, "must be blank for this role") if vendor.present? && !vendor_user?
  end
end
