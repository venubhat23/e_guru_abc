class Ui::EmptyStateComponent < ApplicationComponent
  renders_one :action

  def initialize(title:, body: nil, icon: "inbox")
    @title, @body, @icon = title, body, icon
  end

  def call
    tag.div(class: "flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 bg-white/60 px-6 py-14 text-center") do
      safe_join([
        tag.span(class: "grid h-14 w-14 place-items-center rounded-2xl bg-gradient-to-br from-saffron-100 to-rani-100 text-saffron-600") { icon(@icon, class: "h-7 w-7") },
        tag.h3(@title, class: "mt-4 text-base font-semibold text-slate-900"),
        (@body ? tag.p(@body, class: "mt-1 max-w-sm text-sm text-slate-500") : nil),
        (action? ? tag.div(action, class: "mt-5") : nil)
      ].compact)
    end
  end
end
