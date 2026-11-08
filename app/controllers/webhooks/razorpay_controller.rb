# Razorpay calls this; there is no user session, CSRF token or browser.
class Webhooks::RazorpayController < ActionController::API
  def create
    result = Payments::RazorpayWebhook.new(raw_body: request.raw_post, signature: request.headers["X-Razorpay-Signature"],
                                           event_id: request.headers["X-Razorpay-Event-Id"]).process!
    render json: { status: result }, status: :ok
  rescue Payments::RazorpayWebhook::InvalidSignature
    head :unauthorized
  rescue JSON::ParserError
    head :bad_request
  end
end
