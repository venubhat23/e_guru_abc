# Creates a Razorpay order for the outstanding balance of a booking.
module Payments
  class RazorpayCheckout
    def self.create_order!(booking)
      Razorpay.setup(ENV.fetch("RAZORPAY_KEY_ID"), ENV.fetch("RAZORPAY_KEY_SECRET"))
      order = Razorpay::Order.create(amount: booking.balance_due_paise, currency: "INR", receipt: booking.number, notes: { booking: booking.number })
      booking.payments.create!(method: "razorpay", amount_paise: booking.balance_due_paise, razorpay_order_id: order.id)
    end
  end
end
