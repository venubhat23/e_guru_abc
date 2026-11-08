class Admin::InvoicesController < Admin::BaseController
  def index
    base = policy_scope(Invoice)
    scope = base.includes(:company, :booking)
    scope = scope.where(kind: params[:kind]) if Invoice::KINDS.key?(params[:kind])
    scope = scope.where(financial_year: params[:fy]) if params[:fy].present?
    scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
    scope = scope.where("invoices.number ILIKE ?", "%#{Invoice.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @totals = base.group(:kind).sum(:total_paise)
    @pagy, @invoices = pagy(scope.recent)
    @years = base.distinct.order(financial_year: :desc).pluck(:financial_year)
    @companies = Company.order(:legal_name)
    @vendor_invoices = ActiveStorage::Attachment.where(record_type: "VendorPayout", name: "vendor_invoice").includes(:blob).order(created_at: :desc).limit(10)
  end

  def show
    invoice = policy_scope(Invoice).find(params[:id])
    authorize invoice
    send_data Pdf::InvoicePdf.new(invoice).render, filename: "#{invoice.number.tr('/', '-')}.pdf", type: "application/pdf", disposition: "inline"
  end
end
