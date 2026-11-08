class BookingRecipient < ApplicationRecord
  STATUSES = %w[pending in_production dispatched delivered].freeze
  belongs_to :booking
  belongs_to :employee, optional: true
  belongs_to :assignment, optional: true
  has_many :tickets, dependent: :nullify

  validates :name, :state, :pincode, presence: true
  validates :pincode, format: { with: /\A[1-9]\d{5}\z/ }
  validates :status, inclusion: { in: STATUSES }

  def tracking_url
    return if awb.blank?
    { "Delhivery" => "https://www.delhivery.com/track/package/%s", "Blue Dart" => "https://www.bluedart.com/tracking?trackFor=0&trackNo=%s",
      "DTDC" => "https://www.dtdc.in/tracking.asp?strCnno=%s", "India Post" => "https://www.indiapost.gov.in/?awb=%s" }
      .fetch(courier, "https://www.google.com/search?q=%s") % awb
  end
end
