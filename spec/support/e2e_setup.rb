require_relative './e2e_tests'

E2eTests::Setup.perform
Capybara.default_driver = E2eTests::DRIVER_NAME

module SystemSpecHelper
  def sign_in(user, password: Digest::SHA256.hexdigest('abcd1234abcd1234'))
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
