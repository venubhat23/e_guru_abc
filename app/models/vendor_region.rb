class VendorRegion < ApplicationRecord
  belongs_to :vendor
  validates :state, presence: true
  validates :pincode_prefix, format: { with: /\A\d{1,6}\z/ }, allow_blank: true

  # Most specific rule wins: pincode prefix, else city, else the whole state.
  def covers?(pincode:, state:, city: nil)
    return pincode.to_s.start_with?(pincode_prefix) if pincode_prefix.present?
    return self.state == state && self.city.casecmp?(city.to_s) if self.city.present?
    self.state == state
  end

  def label = [ pincode_prefix.presence && "#{pincode_prefix}xxx", city.presence, state ].compact.join(", ")
end
