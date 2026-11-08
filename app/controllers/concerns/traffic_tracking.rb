# Counts public page views. Skips bots, non-HTML requests and signed-in platform staff.
module TrafficTracking
  extend ActiveSupport::Concern

  VISITOR_COOKIE = :egg_vid

  included do
    after_action :track_page_view, if: :trackable_request?
  end

  private

  def trackable_request?
    request.get? && request.format.html? && response.successful? &&
      !SiteEvent.bot?(request.user_agent) && !Current.user&.platform?
  end

  def track_page_view
    SiteEvent.record!(request:, visitor_id: traffic_visitor_id, kind: "page_view",
                      path: request.path, referrer: request.referer)
  rescue StandardError => e
    Rails.logger.warn("[traffic] page view not recorded: #{e.message}")
  end

  def traffic_visitor_id
    cookies[VISITOR_COOKIE].presence || SecureRandom.alphanumeric(20).tap do |id|
      cookies[VISITOR_COOKIE] = { value: id, expires: 1.year, httponly: true, same_site: :lax }
    end
  end
end
