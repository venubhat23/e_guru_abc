require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "capybara/rspec"
require "capybara/cuprite"
require "webmock/rspec"

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

WebMock.disable_net_connect!(allow_localhost: true)

# Browser tests drive Chrome over CDP (Cuprite); animations are disabled for determinism.
Capybara.disable_animation = true
Capybara.default_max_wait_time = 5 # first render of each template compiles it
Capybara.register_driver(:egg_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [ 1400, 1000 ], headless: true, process_timeout: 20, timeout: 10, js_errors: true,
                                     browser_options: { "no-sandbox" => nil })
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  config.before { Rack::Attack.enabled = false; Rack::Attack.reset! }
  config.before(:each, type: :system) { driven_by :rack_test }
  # Not `driven_by :cuprite`: Rails re-registers that name with its own settings.
  config.before(:each, :js, type: :system) { Capybara.current_driver = :egg_cuprite }
end

Shoulda::Matchers.configure do |config|
  config.integrate { |with| with.test_framework :rspec; with.library :rails }
end
