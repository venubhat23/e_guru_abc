class Package < ApplicationRecord
  has_paper_trail
  belongs_to :occasion
  has_many :package_items, -> { order(:id) }, dependent: :destroy, inverse_of: :package
  has_many :products, through: :package_items
  has_many :vendor_offers, as: :offerable, dependent: :destroy
  has_many :bookings, as: :bookable, dependent: :restrict_with_error
  has_many_attached :images

  accepts_nested_attributes_for :package_items, allow_destroy: true, reject_if: ->(a) { a[:product_id].blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :min_qty, numericality: { only_integer: true, greater_than: 0 }
  validate :has_items
  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def to_param = slug
  def display_emoji = emoji.presence || occasion&.emoji || "🎁"

  # Mixed supply under GST: a hamper is taxed at the highest rate among its items.
  def gst_rate = package_items.map { _1.product.gst_rate }.max || 18
  def principal_product = package_items.max_by { _1.product.gst_rate }&.product
  def hsn_code = principal_product&.hsn_code
  def volume_units = package_items.sum { _1.product.volume_units * _1.quantity }
  def food? = package_items.any? { _1.product.food? }

  private

  def has_items
    errors.add(:base, "Add at least one item") if package_items.reject(&:marked_for_destruction?).empty?
  end
end
