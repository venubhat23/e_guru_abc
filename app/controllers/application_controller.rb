class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Backend


  before_action :set_paper_trail_whodunnit

  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  helper_method :current_user

  private

  def current_user = Current.user
  def pundit_user = Current.user
  def user_for_paper_trail = Current.user&.id

  def forbidden
    respond_to do |format|
      format.html do
        flash[:alert] = "You don't have access to that page."
        redirect_back_or_to(current_user ? portal_home_path(current_user) : root_path)
      end
      format.any { head :forbidden }
    end
  end

  def not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found, layout: "public" }
      format.any { head :not_found }
    end
  end

  def portal_home_path(user)
    case user.portal
    when :admin then admin_root_path
    when :hr then hr_root_path
    else vendor_root_path
    end
  end
  helper_method :portal_home_path
end
