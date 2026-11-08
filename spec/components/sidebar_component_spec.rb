require "rails_helper"

RSpec.describe SidebarComponent, type: :component do
  it "marks the active item and disables future items" do
    user = build(:user, name: "Aarav Mehta")
    sections = [ { title: "Main", items: [ { label: "Leads", icon: "funnel", path: "/admin/leads" }, { label: "Payouts", icon: "banknotes", soon: true } ] } ]
    render_inline(described_class.new(portal: :admin, sections:, user:, current_path: "/admin/leads/5"))
    expect(page).to have_css("a[aria-current='page']", text: "Leads")
    expect(page).to have_css("span", text: "Soon")
    expect(page).not_to have_link("Payouts")
    expect(page).to have_text("AM")
  end
end
