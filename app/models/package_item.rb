class PackageItem < ApplicationRecord
  belongs_to :package
  belongs_to :product
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :product_id, uniqueness: { scope: :package_id }
end
