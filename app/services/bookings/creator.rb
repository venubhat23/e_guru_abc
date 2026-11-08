# Creates a draft booking with recipients and a locked quote.
module Bookings
  class Creator
    class Error < StandardError; end

    def self.call(...) = new(...).call

    def initialize(company:, user:, bookable:, employees:, requested_delivery_on:, delivery_mode: "individual", personalisation: {}, office: nil)
      @company, @user, @bookable, @employees = company, user, bookable, employees.to_a
      @date, @mode, @personalisation, @office = requested_delivery_on.to_date, delivery_mode, personalisation, office
    end

    def call
      validate!
      points = @mode == "bulk_office" ? 1 : @employees.size
      quote = Quote.call(company: @company, bookable: @bookable, quantity: @employees.size, delivery_mode: @mode, delivery_points: points)
      Booking.transaction do
        booking = Booking.create!(
          company: @company, created_by: @user, bookable: @bookable, occasion: @bookable.try(:occasion), quantity: @employees.size,
          delivery_mode: @mode, requested_delivery_on: @date, place_of_supply_state: @company.state, personalisation: @personalisation,
          unit_price_paise: quote.unit_price_paise, hr_subtotal_paise: quote.hr_subtotal_paise, delivery_charge_paise: quote.delivery_charge_paise,
          gst_rate: quote.gst_rate, cgst_paise: quote.gst.cgst_paise, sgst_paise: quote.gst.sgst_paise, igst_paise: quote.gst.igst_paise,
          total_paise: quote.total_paise, assignment_mode: @company.assignment_mode
        )
        @employees.each { |e| booking.recipients.create!(recipient_attrs(e)) }
        booking
      end
    end

    def self.earliest_delivery_date(bookable)
      days = bookable.vendor_offers.active.from_approved_vendors.minimum(:lead_time_days)
      days && Date.current + days
    end

    private

    def validate!
      raise Error, "Select at least one recipient" if @employees.empty?
      min = @bookable.try(:min_qty).to_i
      raise Error, "Minimum order is #{min} kits" if @employees.size < min
      earliest = self.class.earliest_delivery_date(@bookable)
      raise Error, "No vendor currently offers this package" unless earliest
      raise Error, "Earliest possible delivery date is #{earliest.to_fs(:long)}" if @date < earliest
    end

    def recipient_attrs(e)
      base = { employee: e, name: e.name, phone: e.phone, tshirt_size: e.tshirt_size,
               card_message: @personalisation["card_message"].to_s.gsub("{name}", e.name.split.first).presence }
      if @mode == "bulk_office" && @office
        base.merge(address: @office[:address], city: @office[:city], state: @office[:state], pincode: @office[:pincode])
      else
        base.merge(address: e.address, city: e.city, state: e.state, pincode: e.pincode)
      end
    end
  end
end
