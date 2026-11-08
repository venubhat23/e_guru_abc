class Admin::AuditLogsController < Admin::BaseController
  def index
    authorize :audit_log, :index?
    scope = AuditLogPolicy::Scope.new(current_user, PaperTrail::Version).resolve
    scope = scope.where(item_type: params[:type]) if params[:type].present?
    @pagy, @versions = pagy(scope.order(created_at: :desc), limit: 30)
    @actors = User.where(id: @versions.map(&:whodunnit).compact.uniq).index_by { _1.id.to_s }
    @types = PaperTrail::Version.distinct.order(:item_type).pluck(:item_type)
    skip_policy_scope
  end
end
