class LegalPage < ApplicationRecord
  has_paper_trail
  validates :title, :body, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  before_validation { self.slug = title.to_s.parameterize if slug.blank? }
  scope :published, -> { where(published: true) }
  def to_param = slug
end
