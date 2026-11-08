class Hr::TeamMembersController < Hr::BaseController
  def index
    @pagy, @members = pagy(policy_scope(User).ordered, limit: 20)
  end

  def show
    @member = policy_scope(User).find(params[:id])
    authorize @member
  end
end
