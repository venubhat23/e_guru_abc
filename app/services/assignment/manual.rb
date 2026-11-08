# Ops picks a vendor for all remaining recipients, a state, or a number of recipients (split bookings).
class Assignment
  class Manual
    def self.call(booking:, offer:, state: nil, quantity: nil)
      scope = booking.unassigned_recipients.order(:id)
      scope = scope.where(state:) if state.present?
      recipients = quantity.present? ? scope.limit(quantity.to_i).to_a : scope.to_a
      Creator.call(booking:, offer:, recipients:, mode: "manual")
    end
  end
end
