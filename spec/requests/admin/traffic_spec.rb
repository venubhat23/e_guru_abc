require "rails_helper"

RSpec.describe "Traffic analytics" do
  let(:browser) { { "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0) Mobile Safari" } }

  it "records public page views and click beacons, ignoring bots" do
    expect { get root_path, headers: browser }.to change(SiteEvent.page_views, :count).by(1)
    expect(SiteEvent.last).to have_attributes(path: "/", device: "mobile")

    expect { get root_path, headers: { "HTTP_USER_AGENT" => "Googlebot/2.1" } }.not_to change(SiteEvent, :count)

    post site_events_path, params: { path: "/gifts/diwali", label: "Get a quote", href: "/contact" }, headers: browser
    expect(response).to have_http_status(:no_content)
    expect(SiteEvent.clicks.last).to have_attributes(path: "/gifts/diwali", label: "Get a quote", target: "/contact")
  end

  it "does not count signed-in platform staff" do
    sign_in(create(:user, :super_admin))
    expect { get root_path, headers: browser }.not_to change(SiteEvent, :count)
  end

  it "shows the report to super admins only" do
    SiteEvent.insert_all([
      { kind: "page_view", path: "/", visitor_id: "a", device: "desktop", referrer_host: nil, label: nil, target: nil, created_at: 1.hour.ago },
      { kind: "page_view", path: "/", visitor_id: "b", device: "mobile", referrer_host: "google.com", label: nil, target: nil, created_at: 1.hour.ago },
      { kind: "click", path: "/", visitor_id: "a", device: "desktop", referrer_host: nil, label: "Contact us", target: "/contact", created_at: 1.hour.ago }
    ])

    sign_in(create(:user, :super_admin))
    get admin_traffic_path(days: 7)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Traffic analytics", "Contact us", "google.com")

    delete session_path
    sign_in(create(:user, :ops))
    get admin_traffic_path
    expect(response).to redirect_to(admin_root_path)
  end
end
