class Category < ApplicationRecord
  has_paper_trail
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :markup_override_pct, numericality: { greater_than_or_equal_to: 0, less_than: 500 }, allow_nil: true
  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  scope :ordered, -> { order(:position, :name) }
end
