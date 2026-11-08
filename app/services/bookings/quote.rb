# Computes the HR-facing quote for a booking. Never exposes vendor data.
module Bookings
  class Quote
    Result = Struct.new(:unit_price_paise, :quantity, :hr_subtotal_paise, :delivery_charge_paise, :gst_rate, :gst, :total_paise, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(company:, bookable:, quantity:, delivery_mode:, delivery_points:)
      @company, @bookable, @quantity, @delivery_mode, @delivery_points = company, bookable, quantity, delivery_mode, delivery_points
    end

    def call
      unit = Pricing::Calculator.new(company: @company).catalogue_price(@bookable)
      raise ArgumentError, "No active vendor offer for #{@bookable.name}" unless unit
      subtotal = unit * @quantity
      delivery = Setting[:delivery_fee_per_recipient_rupees].to_i * 100 * @delivery_points
      rate = @bookable.gst_rate
      gst = Gst::Splitter.call(taxable_paise: subtotal + delivery, rate:, place_of_supply: @company.state)
      Result.new(unit_price_paise: unit, quantity: @quantity, hr_subtotal_paise: subtotal, delivery_charge_paise: delivery,
                 gst_rate: rate, gst:, total_paise: subtotal + delivery + gst.total_paise)
    end
  end
end
