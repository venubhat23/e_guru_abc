class Employee < ApplicationRecord
  TSHIRT_SIZES = %w[XS S M L XL XXL].freeze
  belongs_to :company
  validates :emp_code, :name, presence: true
  validates :emp_code, uniqueness: { scope: :company_id }
  validates :pincode, format: { with: /\A[1-9]\d{5}\z/ }, allow_blank: true
  validates :tshirt_size, inclusion: { in: TSHIRT_SIZES }, allow_blank: true
  scope :active, -> { where(status: "active") }
end
