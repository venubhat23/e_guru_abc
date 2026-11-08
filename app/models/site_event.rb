# Anonymous public-website traffic: page views (server side) and clicks (JS beacon).
class SiteEvent < ApplicationRecord
  KINDS = %w[page_view click].freeze
  BOT_UA = /bot|crawl|spider|slurp|preview|monitor|headless|lighthouse|curl|wget|python|http/i

  validates :kind, inclusion: { in: KINDS }
  validates :path, :visitor_id, presence: true

  scope :page_views, -> { where(kind: "page_view") }
  scope :clicks, -> { where(kind: "click") }
  scope :since, ->(time) { where(created_at: time..) }

  def self.bot?(user_agent) = user_agent.blank? || user_agent.match?(BOT_UA)

  def self.device_for(user_agent)
    case user_agent.to_s
    when /ipad|tablet/i then "tablet"
    when /mobile|android|iphone/i then "mobile"
    else "desktop"
    end
  end

  # Records one event straight to the table (no callbacks/versioning — it's high volume).
  def self.record!(request:, visitor_id:, kind:, path:, label: nil, target: nil, referrer: nil)
    insert!({
      kind:, visitor_id:,
      path: path.to_s.first(255),
      label: label.to_s.squish.first(120).presence,
      target: target.to_s.first(255).presence,
      referrer_host: external_host(referrer, request.host),
      device: device_for(request.user_agent),
      created_at: Time.current
    })
  end

  def self.external_host(referrer, own_host)
    host = URI.parse(referrer.to_s).host
    host if host.present? && host != own_host
  rescue URI::InvalidURIError
    nil
  end
end
