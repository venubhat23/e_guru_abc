class Admin::PayoutsController < Admin::BaseController
  before_action :set_payout, except: :index

  def index
    base = policy_scope(VendorPayout)
    @counts = base.group(:status).count
    @totals = base.group(:status).sum(:amount_paise)
    @overdue = base.overdue.sum(:amount_paise)
    scope = base.includes(:vendor, assignment: :booking)
    scope = scope.where(status: params[:status]) if params[:status].in?(%w[due approved paid received])
    scope = scope.where(kind: params[:kind]) if params[:kind].in?(VendorPayout::KINDS)
    scope = scope.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
    scope = scope.overdue if params[:overdue] == "1"
    @pagy, @payouts = pagy(scope.order(Arel.sql("CASE status WHEN 'due' THEN 0 WHEN 'approved' THEN 1 WHEN 'paid' THEN 2 ELSE 3 END"), :due_on))
    @vendors = Vendor.order(:business_name)
  end

  def show = authorize(@payout)

  def approve
    authorize @payout
    Payouts::Workflow.approve!(@payout, by: current_user, penalty_paise: Inr.to_paise(params[:penalty_rupees]).to_i, penalty_reason: params[:penalty_reason])
    redirect_to admin_payout_path(@payout), notice: "Payout approved for #{Inr.format(@payout.amount_paise)}."
  rescue Payouts::Workflow::Error, AASM::InvalidTransition, ActiveRecord::RecordInvalid => e
    redirect_to admin_payout_path(@payout), alert: e.message
  end

  def pay
    authorize @payout
    Payouts::Workflow.pay!(@payout, utr: params[:utr])
    redirect_to admin_payout_path(@payout), notice: "Marked as paid (UTR #{@payout.utr}). The vendor will confirm receipt."
  rescue Payouts::Workflow::Error, AASM::InvalidTransition => e
    redirect_to admin_payout_path(@payout), alert: e.message
  end

  private

  def set_payout = @payout = policy_scope(VendorPayout).find(params[:id])
end
