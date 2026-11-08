class Admin::TrafficController < Admin::BaseController
  RANGES = { "7" => 7, "30" => 30, "90" => 90 }.freeze

  def show
    authorize :traffic, :show?
    @days = RANGES.fetch(params[:days].to_s, 30)
    from = (@days - 1).days.ago.beginning_of_day
    events = SiteEvent.since(from)
    views = events.page_views
    clicks = events.clicks

    @stats = {
      views: views.count,
      visitors: views.distinct.count(:visitor_id),
      clicks: clicks.count,
      today: SiteEvent.page_views.since(Time.current.beginning_of_day).count
    }
    @stats[:ctr] = @stats[:views].zero? ? 0 : (@stats[:clicks] * 100.0 / @stats[:views]).round(1)

    @daily = [
      { name: "Page views", data: views.group_by_day(:created_at, range: from..Time.current, format: "%d %b").count },
      { name: "Clicks", data: clicks.group_by_day(:created_at, range: from..Time.current, format: "%d %b").count }
    ]
    @top_pages = views.group(:path).order("count_all DESC").limit(10).count
    @page_visitors = views.where(path: @top_pages.keys).group(:path).distinct.count(:visitor_id)
    @top_clicks = clicks.group(:label, :target).order("count_all DESC").limit(12).count
    @referrers = views.where.not(referrer_host: nil).group(:referrer_host).order("count_all DESC").limit(8).count
    @devices = views.group(:device).count.transform_keys { _1.to_s.capitalize }
  end
end
