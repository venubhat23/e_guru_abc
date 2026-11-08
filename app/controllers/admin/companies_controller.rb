class Admin::CompaniesController < Admin::BaseController
  def index
    scope = policy_scope(Company)
    scope = scope.where("legal_name ILIKE :q OR display_name ILIKE :q OR gstin ILIKE :q", q: "%#{Company.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @pagy, @companies = pagy(scope.order(created_at: :desc), limit: 20)
    @user_counts = User.where(company_id: @companies.map(&:id)).group(:company_id).count
  end

  def show
    @company = policy_scope(Company).find(params[:id])
    authorize @company
    @users = @company.users.ordered
    @lead = @company.leads.first
  end
end
