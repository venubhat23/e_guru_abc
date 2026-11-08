# Browser-test stability helpers (Cuprite / Chrome CDP).
#
# Defensive: before each click and after each visit, wait for web fonts (Google Fonts, display=swap)
# and two painted frames so layout has settled. (Under Selenium + headless Chrome, clicks issued
# right after a page change were silently dropped; Cuprite plus this wait is stable.)
module SystemHelpers
  FRAME_WAIT_JS = <<~JS.freeze
    const done = arguments[arguments.length - 1];
    (document.fonts ? document.fonts.ready : Promise.resolve())
      .then(() => requestAnimationFrame(() => requestAnimationFrame(() => done(true))));
  JS

  def self.wait_for_paint(session)
    return unless session.mode == :egg_cuprite
    session.evaluate_async_script(FRAME_WAIT_JS)
  rescue Capybara::NotSupportedByDriverError, Ferrum::JavaScriptError
    nil
  end

  module ElementClick
    def click(*args, **opts)
      SystemHelpers.wait_for_paint(session)
      super
    end
  end

  def visit(...)
    super
    SystemHelpers.wait_for_paint(page)
  end
end

Capybara::Node::Element.prepend(SystemHelpers::ElementClick)
RSpec.configure { |c| c.include SystemHelpers, type: :system }
