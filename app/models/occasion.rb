class Occasion < ApplicationRecord
  has_paper_trail
  THEMES = %w[saffron rani plum emerald sky].freeze

  has_many :leads, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :theme, inclusion: { in: THEMES }
  validates :from_price_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def to_param = slug

  def from_price_rupees = from_price_paise && from_price_paise / 100
  def highlights_text = Array(highlights).join("\n")

  def in_season?(date = Date.current)
    return false unless season_starts_on && season_ends_on
    (season_starts_on..season_ends_on).cover?(date)
  end
end
