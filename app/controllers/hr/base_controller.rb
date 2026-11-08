# Every HR request is scoped to the signed-in user's company (Current.company).
class Hr::BaseController < ApplicationController
  include Portal
  layout "hr"
  portal_roles User::HR_ROLES
  before_action :set_tenant

  private

  def set_tenant
    Current.company = current_user.company
    redirect_to(new_session_path, alert: "Your company account is inactive.") unless Current.company&.active?
  end
end
