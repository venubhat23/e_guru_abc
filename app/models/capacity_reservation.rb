class CapacityReservation < ApplicationRecord
  belongs_to :vendor_offer
  belongs_to :assignment
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :week_start, presence: true
end
