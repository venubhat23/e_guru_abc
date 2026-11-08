# Receives click beacons from the public site (navigator.sendBeacon, so no CSRF token).
class SiteEventsController < ApplicationController
  include TrafficTracking
  allow_unauthenticated_access
  skip_forgery_protection
  before_action :resume_session

  def create
    path = URI.parse(params[:path].to_s).path.presence
    if path && !SiteEvent.bot?(request.user_agent) && !Current.user&.platform?
      SiteEvent.record!(request:, visitor_id: traffic_visitor_id, kind: "click",
                        path:, label: params[:label], target: params[:href])
    end
    head :no_content
  rescue URI::InvalidURIError
    head :no_content
  end
end
