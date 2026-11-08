class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, except: :index

  def index
    base = policy_scope(Booking)
    @counts = base.group(:status).count
    scope = base.includes(:company, :occasion, :bookable)
    scope = scope.where(status: params[:status]) if Booking::STATUS_LABELS.key?(params[:status])
    scope = scope.where(status: Booking::OPEN) if params[:status] == "open"
    scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
    scope = scope.where(occasion_id: params[:occasion_id]) if params[:occasion_id].present?
    scope = scope.where(assignment_mode: params[:mode]) if params[:mode].in?(%w[auto manual])
    scope = scope.where("bookings.number ILIKE ?", "%#{Booking.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @pagy, @bookings = pagy(scope.recent, limit: 20)
    @companies = Company.order(:legal_name)
    @occasions = Occasion.ordered
  end

  def show
    authorize @booking
    @recipients = @booking.recipients.includes(:assignment).order(:state, :name)
    @assignments = @booking.assignments.includes(:vendor, :payouts).order(:created_at)
    @payments = @booking.payments.recent
    @invoices = @booking.invoices.recent
    @tickets = @booking.tickets.recent
    @ledger = @booking.ledger_entries.index_by(&:account)
    @candidates = Assignment::Eligibility.new(@booking).candidates if @booking.assigning? && @booking.unassigned_recipients.exists?
    @unassigned_states = @booking.unassigned_recipients.group(:state).count
    @versions = @booking.versions.order(created_at: :desc).limit(25)
  end

  def auto_assign
    authorize @booking
    assignment = Assignment::AutoAssigner.call(@booking)
    redirect_to admin_booking_path(@booking), assignment ? { notice: "Offered to #{assignment.vendor.name}." } : { alert: "No eligible vendor — booking switched to manual assignment." }
  end

  def manual_assign
    authorize @booking
    offer = VendorOffer.find(params[:vendor_offer_id])
    a = Assignment::Manual.call(booking: @booking, offer:, state: params[:state], quantity: params[:quantity].presence)
    redirect_to admin_booking_path(@booking), notice: "#{a.quantity} kits offered to #{a.vendor.name}."
  rescue Assignment::Creator::Error, ActiveRecord::RecordInvalid => e
    redirect_to admin_booking_path(@booking), alert: e.message
  end

  def cancel
    authorize @booking
    Bookings::Canceller.call(booking: @booking, reason: params[:reason], actor: current_user)
    redirect_to admin_booking_path(@booking), notice: "Booking cancelled. Any payment was refunded with a credit note."
  rescue Bookings::Canceller::Error, AASM::InvalidTransition => e
    redirect_to admin_booking_path(@booking), alert: e.message
  end

  def confirm_delivery
    authorize @booking
    return redirect_to(admin_booking_path(@booking), alert: "Every recipient must be delivered first.") unless @booking.may_mark_delivered?
    @booking.mark_delivered!
    Bookings::Completer.call(@booking)
    redirect_to admin_booking_path(@booking), notice: "Delivery confirmed."
  end

  def dispute
    authorize @booking
    @booking.dispute_reason = params[:reason]
    return redirect_to(admin_booking_path(@booking), alert: "Give a dispute reason.") unless @booking.may_dispute?
    @booking.dispute!
    redirect_to admin_booking_path(@booking), notice: "Booking marked as disputed. Vendor balance payouts are on hold."
  end

  def resolve_dispute
    authorize @booking
    return redirect_to(admin_booking_path(@booking), alert: "All recipients must be delivered to resolve.") unless @booking.may_mark_delivered?
    @booking.mark_delivered!
    redirect_to admin_booking_path(@booking), notice: "Dispute resolved — booking back to delivered."
  end

  def proforma
    authorize @booking
    send_data Pdf::ProformaPdf.new(@booking).render, filename: "proforma-#{@booking.number}.pdf", type: "application/pdf", disposition: "inline"
  end

  def delivery_report
    authorize @booking
    send_data Reports::DeliveryReport.csv(@booking), filename: "delivery-report-#{@booking.number}.csv", type: "text/csv"
  end

  private

  def set_booking = @booking = policy_scope(Booking).find_by!(number: params[:id])
end
