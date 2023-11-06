if ENV['RUN_SYSTEM_TESTS']
  require_relative './e2e_tests'
  E2eTests::Setup.perform
  Capybara.default_driver = E2eTests::DRIVER_NAME
end

# test helper methods
module SystemSpecHelper
  # from user factory
  DEFAULT_USER_PASSWORD = Digest::SHA256.hexdigest('abcd1234abcd1234')

  def sign_in(user, password: DEFAULT_USER_PASSWORD)
    visit('/')
    fill_in 'Email Address', with: user.email
    fill_in 'Password', with: password
    click_button('Sign In')
  end

  def sign_out
    find('#userMenuToggle').click
    # FIXME: sign out button needs a11y
    find('span', text: 'Sign Out').click
  end

  def set_hidden_field_value(id, value)
    find_field(id, type: :hidden).set(value)
  end
end

RSpec.configure do |config|
  next unless ENV['RUN_SYSTEM_TESTS']

  config.include E2eTests::Helpers, type: :system
  config.include SystemSpecHelper, type: :system

  config.prepend_before(:each, type: :system) do
    # Use JS driver always
    driven_by E2eTests::DRIVER_NAME
  end

  # Make urls in mailers contain the correct server host.
  # It's required for testing links in emails (e.g., via capybara-email).
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host
    ex.run
    Rails.application.default_url_options[:host] = was_host
  end
end
