class Ui::StatCardComponent < ApplicationComponent
  TONES = {
    orange: "from-saffron-500 to-marigold-500",
    pink: "from-rani-500 to-saffron-400",
    purple: "from-plum-600 to-rani-500",
    green: "from-emerald-500 to-teal-400",
    blue: "from-sky-500 to-indigo-500"
  }.freeze

  def initialize(label:, value:, icon: "chart", tone: :orange, hint: nil, href: nil)
    @label, @value, @icon, @tone, @hint, @href = label, value, icon, tone.to_sym, hint, href
  end

  def call
    body = tag.div(class: "card card-body group relative overflow-hidden transition hover:-translate-y-0.5 hover:shadow-md") do
      safe_join([
        tag.div(class: "absolute -right-6 -top-6 h-24 w-24 rounded-full bg-gradient-to-br #{TONES[@tone]} opacity-10 transition group-hover:scale-125"),
        tag.div(class: "flex items-start justify-between gap-3") do
          safe_join([
            tag.div do
              safe_join([
                tag.p(@label, class: "text-sm font-medium text-slate-500"),
                tag.p(@value, class: "mt-2 text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl"),
                (@hint ? tag.p(@hint, class: "mt-1 text-xs text-slate-500") : nil)
              ].compact)
            end,
            tag.span(class: "grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-gradient-to-br #{TONES[@tone]} text-white shadow-lg") { icon(@icon, class: "h-5 w-5") }
          ])
        end
      ])
    end
    @href ? link_to(body, @href, class: "block") : body
  end
end
