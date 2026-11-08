class NotificationsController < ApplicationController
  def show
    notification = policy_scope(Notification).find(params[:id])
    authorize notification, :update?
    notification.mark_read!
    redirect_to notification.url.presence || portal_home_path(current_user)
  end

  def read_all
    policy_scope(Notification).unread.update_all(read_at: Time.current)
    redirect_back_or_to portal_home_path(current_user), notice: "All notifications marked as read."
  end
end
