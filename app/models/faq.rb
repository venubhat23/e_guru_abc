class Faq < ApplicationRecord
  has_paper_trail
  AUDIENCES = %w[public vendor].freeze
  validates :question, :answer, presence: true
  validates :audience, inclusion: { in: AUDIENCES }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }
  scope :for, ->(audience) { active.where(audience:).ordered }
end
