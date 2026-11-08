require "rails_helper"

RSpec.describe Payments::RazorpayWebhook do
  let(:secret) { "whsec_test" }
  let(:company) { create(:company) }
  let(:package) { create(:package) }
  let(:booking) { vendor_with_offer(package:); draft_booking(company:, package:).tap(&:submit!) }
  let!(:payment) { booking.payments.create!(method: "razorpay", amount_paise: booking.total_paise, razorpay_order_id: "order_123") }
  let(:body) { { event: "payment.captured", payload: { payment: { entity: { id: "pay_ABC", order_id: "order_123", fee: 2360 } } } }.to_json }
  let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", secret, body) }

  def process(sig: signature, event_id: "evt_1") = described_class.new(raw_body: body, signature: sig, event_id:, secret:).process!

  it "verifies the payment, records the fee and moves the booking to assignment" do
    expect(booking).to be_awaiting_payment
    expect(process).to eq(:processed)
    expect(payment.reload).to be_verified
    expect(payment.gateway_fee_paise).to eq(2360)
    expect(booking.reload.status).to eq("assigned")
  end

  it "is idempotent: the same event id is processed once" do
    process
    expect { expect(process).to eq(:duplicate) }.not_to change(WebhookEvent, :count)
    expect(booking.reload.paid_paise).to eq(booking.total_paise)
  end

  it "rejects bad signatures without touching data" do
    expect { process(sig: "forged") }.to raise_error(described_class::InvalidSignature)
    expect(payment.reload).to be_pending
    expect(WebhookEvent.count).to eq(0)
  end

  it "marks failed payments" do
    failed = { event: "payment.failed", payload: { payment: { entity: { id: "pay_X", order_id: "order_123" } } } }.to_json
    described_class.new(raw_body: failed, signature: OpenSSL::HMAC.hexdigest("SHA256", secret, failed), event_id: "evt_f", secret:).process!
    expect(payment.reload).to be_failed
  end

  describe "endpoint" do
    it "returns 401 for bad signatures and 200 for duplicates", type: :request do
      stub_const("ENV", ENV.to_h.merge("RAZORPAY_WEBHOOK_SECRET" => secret))
      post razorpay_webhook_path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Razorpay-Signature" => "nope" }
      expect(response).to have_http_status(:unauthorized)
      2.times { post razorpay_webhook_path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Razorpay-Signature" => signature, "X-Razorpay-Event-Id" => "evt_9" } }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("duplicate")
    end
  end
end
