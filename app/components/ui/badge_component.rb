class Ui::BadgeComponent < ApplicationComponent
  TONES = {
    gray: "bg-slate-100 text-slate-700 ring-slate-200",
    orange: "bg-saffron-50 text-saffron-700 ring-saffron-200",
    pink: "bg-rani-50 text-rani-700 ring-rani-200",
    purple: "bg-plum-50 text-plum-700 ring-plum-200",
    green: "bg-emerald-50 text-emerald-700 ring-emerald-200",
    red: "bg-red-50 text-red-700 ring-red-200",
    blue: "bg-sky-50 text-sky-700 ring-sky-200",
    yellow: "bg-amber-50 text-amber-800 ring-amber-200"
  }.freeze

  def initialize(text:, tone: :gray, dot: true)
    @text, @tone, @dot = text, tone.to_sym, dot
  end

  def call
    tag.span(class: "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ring-inset #{TONES.fetch(@tone, TONES[:gray])}") do
      safe_join([ (@dot ? tag.span(class: "h-1.5 w-1.5 rounded-full bg-current opacity-70") : nil), @text ].compact)
    end
  end
end
