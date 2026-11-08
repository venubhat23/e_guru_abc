class Vendor < ApplicationRecord
  include AASM
  has_paper_trail skip: %i[bank_account_number]

  encrypts :bank_account_number

  has_many :users, dependent: :restrict_with_error
  has_many :regions, class_name: "VendorRegion", dependent: :destroy
  has_many :offers, class_name: "VendorOffer", dependent: :destroy
  has_many :assignments, dependent: :restrict_with_error
  has_many :payouts, class_name: "VendorPayout", dependent: :restrict_with_error
  has_many :proposed_products, class_name: "Product", foreign_key: :proposed_by_vendor_id, dependent: :nullify, inverse_of: :proposed_by_vendor
  has_many_attached :kyc_documents

  validates :business_name, presence: true, length: { maximum: 200 }
  validates :gstin, format: { with: Gstin::FORMAT, message: "is not a valid GSTIN" }, allow_blank: true
  validates :pan, format: { with: /\A[A-Z]{5}[0-9]{4}[A-Z]\z/, message: "is not a valid PAN" }, allow_blank: true
  validates :bank_ifsc, format: { with: /\A[A-Z]{4}0[A-Z0-9]{6}\z/, message: "is not a valid IFSC" }, allow_blank: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  normalizes :gstin, :pan, :bank_ifsc, with: ->(v) { v.to_s.strip.upcase.presence }

  aasm column: :status, whiny_persistence: true do
    state :pending, initial: true
    state :approved, :rejected, :suspended

    event :approve do
      transitions from: %i[pending rejected suspended], to: :approved, guard: :kyc_complete?
      after { update_columns(approved_at: Time.current, rejection_reason: nil, suspension_reason: nil) }
    end
    event :reject do
      transitions from: :pending, to: :rejected, guard: -> { rejection_reason.present? }
    end
    event :suspend do
      transitions from: :approved, to: :suspended, guard: -> { suspension_reason.present? }
      after { update_column(:suspended_at, Time.current) }
    end
  end

  def name = business_name

  def kyc_complete?
    kyc_missing.empty?
  end

  def kyc_missing
    missing = []
    missing << "GSTIN" if gstin.blank?
    missing << "PAN" if pan.blank?
    missing << "FSSAI licence (food supplier)" if needs_fssai? && fssai_number.blank?
    missing << "Bank account" if bank_account_number.blank? || bank_ifsc.blank?
    missing << "Warehouse address" if warehouse_address.blank?
    missing
  end

  # Food supplier if any offer is for a food product, or a package containing one (single EXISTS query).
  def needs_fssai?
    food = Product.joins(:category).where(categories: { food: true }).select(:id)
    offers.where(offerable_type: "Product", offerable_id: food)
          .or(offers.where(offerable_type: "Package", offerable_id: PackageItem.where(product_id: food).select(:package_id)))
          .exists?
  end

  def masked_account = bank_account_number.present? ? "•••• #{bank_account_number.to_s.last(4)}" : "—"

  def covers_pincode?(pincode:, state:, city: nil)
    regions.any? { _1.covers?(pincode:, state:, city:) }
  end

  # ---- Performance ----
  def performance
    stats = assignments.group(:status).count
    total = stats.values.sum
    declined = stats.values_at("rejected", "expired").compact.sum
    delivered = assignments.where(status: "delivered").joins(:booking)
    on_time = delivered.where("assignments.delivered_at::date <= bookings.requested_delivery_on").count
    {
      total:, declined:, delivered: delivered.count,
      rejection_pct: total.zero? ? 0 : (declined * 100.0 / total).round(1),
      on_time_pct: delivered.count.zero? ? nil : (on_time * 100.0 / delivered.count).round(1)
    }
  end
end
