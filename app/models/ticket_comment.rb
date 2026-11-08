class TicketComment < ApplicationRecord
  belongs_to :ticket
  belongs_to :user, optional: true
  validates :body, presence: true
end
