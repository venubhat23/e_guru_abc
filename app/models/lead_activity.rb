class LeadActivity < ApplicationRecord
  KINDS = %w[created note status_change owner_change follow_up converted email].freeze
  belongs_to :lead
  belongs_to :user, optional: true
  validates :kind, inclusion: { in: KINDS }
  validates :body, presence: true, if: -> { kind == "note" }
end
