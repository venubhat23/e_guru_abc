class Admin::AssignmentsController < Admin::BaseController
  before_action :set_assignment, except: :index

  def index
    base = policy_scope(Assignment)
    @counts = base.group(:status).count
    @breached = base.sla_breached.count
    scope = base.includes(:vendor, booking: :company)
    scope = scope.where(status: params[:status]) if Assignment::STATUS_LABELS.key?(params[:status])
    scope = scope.sla_breached if params[:sla] == "breached"
    scope = scope.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
    @pagy, @assignments = pagy(scope.order(Arel.sql("CASE WHEN assignments.status = 'offered' THEN 0 ELSE 1 END"), expires_at: :asc, created_at: :desc))
    @vendors = Vendor.order(:business_name)
  end

  def show
    authorize @assignment
    @recipients = @assignment.recipients.order(:name)
  end

  def expire
    authorize @assignment
    return redirect_to(admin_assignment_path(@assignment), alert: "Only offered assignments can be expired.") unless @assignment.offered?
    Assignment::Workflow.expire!(@assignment)
    redirect_to admin_booking_path(@assignment.booking), notice: "Assignment expired; capacity released and booking returned to assigning."
  end

  def packing_list
    authorize @assignment
    send_data Pdf::PackingListPdf.new(@assignment).render, filename: "packing-list-#{@assignment.booking.number}-#{@assignment.id}.pdf", type: "application/pdf", disposition: "inline"
  end

  def labels
    authorize @assignment
    send_data Pdf::LabelsPdf.new(@assignment).render, filename: "labels-#{@assignment.booking.number}-#{@assignment.id}.pdf", type: "application/pdf", disposition: "inline"
  end

  private

  def set_assignment = @assignment = policy_scope(Assignment).find(params[:id])
end
