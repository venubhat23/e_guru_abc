class Product < ApplicationRecord
  has_paper_trail
  REVIEW_STATUSES = %w[approved pending rejected].freeze
  GST_RATES = [ 0, 5, 12, 18, 28 ].freeze

  belongs_to :category
  belongs_to :proposed_by_vendor, class_name: "Vendor", optional: true
  has_many :package_items, dependent: :restrict_with_error
  has_many :packages, through: :package_items
  has_many :vendor_offers, as: :offerable, dependent: :destroy
  has_many_attached :images

  validates :name, :sku, :hsn_code, presence: true
  validates :sku, uniqueness: { case_sensitive: false }
  validates :hsn_code, format: { with: /\A\d{4,8}\z/, message: "must be 4–8 digits" }
  validates :gst_rate, inclusion: { in: GST_RATES, message: "must be 0, 5, 12, 18 or 28" }
  validates :volume_units, numericality: { only_integer: true, greater_than: 0 }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :markup_override_pct, numericality: { greater_than_or_equal_to: 0, less_than: 500 }, allow_nil: true
  normalizes :sku, with: ->(s) { s.strip.upcase }

  scope :approved, -> { where(review_status: "approved") }
  scope :pending_review, -> { where(review_status: "pending") }
  scope :sellable, -> { approved.where(active: true) }
  scope :ordered, -> { order(:name) }

  def display_emoji = emoji.presence || category&.emoji || "🎁"
  def food? = category&.food?
end
