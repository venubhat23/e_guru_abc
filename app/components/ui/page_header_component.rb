class Ui::PageHeaderComponent < ApplicationComponent
  renders_one :actions

  def initialize(title:, subtitle: nil, eyebrow: nil)
    @title, @subtitle, @eyebrow = title, subtitle, eyebrow
  end

  def call
    tag.div(class: "mb-6 flex flex-col gap-4 sm:mb-8 sm:flex-row sm:items-end sm:justify-between") do
      safe_join([
        tag.div do
          safe_join([
            (@eyebrow ? tag.p(@eyebrow, class: "text-xs font-semibold uppercase tracking-widest text-saffron-600") : nil),
            tag.h1(@title, class: "mt-1 text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl"),
            (@subtitle ? tag.p(@subtitle, class: "mt-1.5 text-sm text-slate-500") : nil)
          ].compact)
        end,
        (actions? ? tag.div(actions, class: "flex flex-wrap items-center gap-2") : nil)
      ].compact)
    end
  end
end
