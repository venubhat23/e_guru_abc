# Signature-verified, idempotent Razorpay webhook processing.
module Payments
  class RazorpayWebhook
    class InvalidSignature < StandardError; end

    def initialize(raw_body:, signature:, event_id:, secret: ENV["RAZORPAY_WEBHOOK_SECRET"])
      @raw_body, @signature, @event_id, @secret = raw_body, signature.to_s, event_id, secret.to_s
    end

    def process!
      verify_signature!
      payload = JSON.parse(@raw_body)
      event_id = @event_id.presence || Digest::SHA256.hexdigest(@raw_body)

      WebhookEvent.transaction do
        event = WebhookEvent.create!(provider: "razorpay", event_id:, event_type: payload["event"], payload:)
        handle(payload)
        event.update!(processed_at: Time.current)
      end
      :processed
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      raise unless e.is_a?(ActiveRecord::RecordNotUnique) || e.record.is_a?(WebhookEvent)
      :duplicate
    end

    private

    def verify_signature!
      raise InvalidSignature, "Webhook secret not configured" if @secret.blank?
      expected = OpenSSL::HMAC.hexdigest("SHA256", @secret, @raw_body)
      raise InvalidSignature, "Signature mismatch" unless ActiveSupport::SecurityUtils.secure_compare(expected, @signature)
    end

    def handle(payload)
      entity = payload.dig("payload", "payment", "entity") || {}
      payment = Payment.find_by(razorpay_order_id: entity["order_id"])
      return unless payment

      case payload["event"]
      when "payment.captured", "order.paid"
        return unless payment.pending?
        payment.update!(razorpay_payment_id: entity["id"], gateway_fee_paise: entity["fee"].to_i)
        payment.verify!
        Bookings::PaymentApplier.call(payment.booking)
      when "payment.failed"
        payment.fail! if payment.pending?
      end
    end
  end
end
