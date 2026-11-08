# Shared behaviour for authenticated portal namespaces (admin, hr, vendor).
module Portal
  extend ActiveSupport::Concern

  included do
    before_action :require_portal_access
    after_action :verify_authorized, unless: -> { action_name == "index" }
    after_action :verify_policy_scoped, if: -> { action_name == "index" }
    helper_method :unread_notifications
  end

  class_methods do
    def portal_roles(*roles) = (@portal_roles = roles.flatten.map(&:to_s))
    def allowed_portal_roles = @portal_roles || superclass.try(:allowed_portal_roles) || []
  end

  private

  def require_portal_access
    return if self.class.allowed_portal_roles.include?(current_user.role)
    redirect_to portal_home_path(current_user), alert: "That area isn't available for your account."
  end

  def unread_notifications
    @unread_notifications ||= current_user.notifications.unread.recent.limit(8)
  end
end
