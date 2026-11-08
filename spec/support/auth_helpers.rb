module AuthHelpers
  module Request
    def sign_in(user, password: "Password@123")
      post session_path, params: { email_address: user.email_address, password: }
    end
  end

  module System
    def sign_in(user, password: "Password@123")
      visit new_session_path
      fill_in "Email", with: user.email_address
      fill_in "Password", with: password
      click_button "Sign in"
      # Wait for the login round-trip so the next visit carries the session cookie.
      expect(page).to have_no_current_path(new_session_path, wait: 5) if user.email_verified? && user.active?
    end
  end
end

RSpec.configure do |config|
  config.include AuthHelpers::Request, type: :request
  config.include AuthHelpers::System, type: :system
end
