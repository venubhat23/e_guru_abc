class Hr::DashboardController < Hr::BaseController
  def show
    authorize Current.company, :show?
    @company = Current.company
    @team_count = policy_scope(User).count
  end
end
