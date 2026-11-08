# Portal sidebar. Sections: [{ title:, items: [{ label:, icon:, path:, match:, soon:, badge: }] }]
class SidebarComponent < ApplicationComponent
  THEMES = {
    admin: { bg: "bg-plum-950", glow: "from-rani-500/30 via-plum-700/20 to-transparent", accent: "from-saffron-500 to-rani-500", muted: "text-plum-300/70", text: "text-plum-100", hover: "hover:bg-white/5 hover:text-white", tag: "Platform" },
    hr: { bg: "bg-[#1d1033]", glow: "from-saffron-500/30 via-rani-600/10 to-transparent", accent: "from-saffron-500 to-marigold-500", muted: "text-plum-300/70", text: "text-plum-100", hover: "hover:bg-white/5 hover:text-white", tag: "HR Workspace" },
    vendor: { bg: "bg-[#0c2421]", glow: "from-emerald-400/25 via-teal-600/10 to-transparent", accent: "from-emerald-500 to-teal-400", muted: "text-emerald-200/60", text: "text-emerald-50", hover: "hover:bg-white/5 hover:text-white", tag: "Vendor Partner" }
  }.freeze

  def initialize(portal:, sections:, user:, tenant_name: nil, current_path: "")
    @portal, @sections, @user, @tenant_name, @current_path = portal, sections, user, tenant_name, current_path
    @theme = THEMES.fetch(portal)
  end

  attr_reader :theme, :sections, :user, :tenant_name

  def active?(item)
    return false if item[:soon] || item[:path].blank?
    match = item[:match] || item[:path]
    match.is_a?(Regexp) ? @current_path.match?(match) : (@current_path == match || @current_path.start_with?("#{match}/"))
  end
end
