class Admin::PaymentsController < Admin::BaseController
  before_action :set_payment, except: :index

  def index
    base = policy_scope(Payment)
    @counts = base.group(:status).count
    @totals = base.group(:status).sum(:amount_paise)
    scope = base.includes(booking: :company)
    scope = scope.where(status: params[:status]) if params[:status].in?(%w[pending verified failed refunded])
    scope = scope.where(method: params[:method]) if Payment::METHODS.key?(params[:method])
    scope = scope.where(status: "pending").where.not(method: "razorpay") if params[:queue] == "offline"
    @pagy, @payments = pagy(scope.recent)
  end

  def show = authorize(@payment)

  def verify
    authorize @payment
    Payments::Recorder.verify!(@payment, by: current_user)
    redirect_to admin_payment_path(@payment), notice: "Payment verified. Booking #{@payment.booking.number} is now #{@payment.booking.reload.status_label.downcase}."
  end

  def reject
    authorize @payment
    Payments::Recorder.reject!(@payment, by: current_user, notes: params[:notes])
    redirect_to admin_payment_path(@payment), notice: "Payment marked as failed."
  end

  private

  def set_payment = @payment = policy_scope(Payment).find(params[:id])
end
