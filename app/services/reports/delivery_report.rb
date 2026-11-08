require "csv"
# Per-recipient delivery report for HR. Contains no vendor information.
module Reports
  class DeliveryReport
    def self.csv(booking)
      CSV.generate do |csv|
        csv << [ "Booking", "Employee", "City", "State", "Pincode", "Status", "Courier", "AWB", "Dispatched at", "Delivered at" ]
        booking.recipients.order(:name).each do |r|
          csv << [ booking.number, r.name, r.city, r.state, r.pincode, r.status.humanize, r.courier, r.awb,
                  r.dispatched_at&.strftime("%d-%m-%Y %H:%M"), r.delivered_at&.strftime("%d-%m-%Y %H:%M") ]
        end
      end
    end
  end
end
