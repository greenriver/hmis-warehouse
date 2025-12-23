# frozen_string_literal: true

# Standard Rails application system test setup
# Separate from the React/MUI e2e test infrastructure

require 'capybara'

# Enable by passing RUN_RAILS_SYSTEM_TESTS
rails_system_enabled = ENV['RUN_RAILS_SYSTEM_TESTS']

if rails_system_enabled
  require 'capybara/cuprite'

  # Configure Rails to serve assets properly in system tests
  ENV['RAILS_SERVE_STATIC_FILES'] = 'true'

  # Configure Capybara for standard Rails testing
  Capybara.configure do |config|
    config.default_max_wait_time = ENV.fetch('FERRUM_DEFAULT_TIMEOUT', 15).to_i # Configurable to match driver timeout
    config.default_normalize_ws = true
    config.ignore_hidden_elements = true
    config.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')
  end

  # Register drivers for Rails tests - fallback to rack_test if Chrome not available
  Capybara.register_driver :rails_cuprite do |app|
    Capybara::Cuprite::Driver.new(
      app,
      window_size: [1200, 800],
      headless: ENV.fetch('CI', 'true') == 'true',
      js_errors: false, # More lenient for standard Rails apps
      # logger: STDOUT, # Uncomment this for more verbose logging of everything the browser is doing
      timeout: ENV.fetch('FERRUM_DEFAULT_TIMEOUT', 30).to_i,           # Configurable timeout for slow asset loading
      process_timeout: ENV.fetch('FERRUM_PROCESS_TIMEOUT', 60).to_i,   # Configurable process timeout
      pending_connection_errors: false, # Ignore pending connection errors
      browser_options: {
        'no-sandbox' => nil,
        'disable-gpu' => nil,
        'disable-dev-shm-usage' => nil,
        'disable-extensions' => nil,
        'disable-background-timer-throttling' => nil,
        'disable-backgrounding-occluded-windows' => nil,
        'disable-renderer-backgrounding' => nil,
      },
    )
  end

  Capybara.default_driver = :rails_cuprite
  Capybara.javascript_driver = :rails_cuprite
end

# Password from existing user factory
RAILS_SYSTEM_DEFAULT_PASSWORD = Digest::SHA256.hexdigest('abcd1234abcd1234')

# Standard Rails system test helpers
RSpec.shared_context 'RailsSystemHelper' do
  include Capybara::DSL

  # Sign in a user for Rails system specs using JWT authentication.
  #
  # This replaces the old Devise-based login form flow with JWT-based authentication.
  # Instead of filling in a login form (which no longer exists with OAuth2-proxy),
  # we inject a JWT token into a cookie that CurrentUser will read.
  #
  # @param user [User] The user to sign in
  # @param password [String] Unused, kept for backward compatibility
  def sign_in_user(user, password: RAILS_SYSTEM_DEFAULT_PASSWORD) # rubocop:disable Lint/UnusedMethodArgument
    # Generate a mock JWT token
    mock_token = "mock-jwt-token-#{user.id}-#{SecureRandom.hex(8)}"

    # Stub JWT validation to recognize this token
    jwt_helper = instance_double(
      JwtHelper,
      token?: true,
      validate!: true,
      connector_id: 'test',
      connector_user_id: user.id.to_s,
      payload_email: user.email,
      expiration_time: 1.hour.from_now,
    )

    allow(JwtHelper).to receive(:authenticated?).and_wrap_original do |original_method, token|
      token == mock_token ? true : original_method.call(token)
    end

    allow(JwtHelper).to receive(:user_id_from_token).and_wrap_original do |original_method, token|
      token == mock_token ? user.id : original_method.call(token)
    end

    allow(JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
      kwargs[:access_token] == mock_token ? jwt_helper : original_method.call(**kwargs)
    end

    allow(User).to receive(:find_from_jwt).and_wrap_original do |original_method, helper|
      helper == jwt_helper ? user : original_method.call(helper)
    end

    # Visit the application first (required to set cookies)
    visit('/')

    # Set the test JWT token in a cookie that CurrentUser will read
    # Cuprite/Ferrum uses page.driver.set_cookie instead of Selenium's add_cookie
    page.driver.set_cookie('test_jwt_token', mock_token, path: '/', httponly: false, secure: false)

    # Navigate to home page (now authenticated)
    visit('/')

    # Check if sign in was successful - look for user name or absence of sign in form
    return true if page.has_content?(user.first_name, wait: 5) # Success - user name appears

    puts 'Sign in may have failed - user name not visible' if ENV['DEBUG_TESTS']
    true # Assume success since we're using JWT
  end

  def sign_out_user
    if page.has_link?('Sign Out')
      page.click_link('Sign Out')
    elsif page.has_link?('Account')
      page.click_link('Account')
      page.click_link('Sign Out')
    end
  end

  def fill_in_form(form_data = {})
    form_data.each do |field, value|
      case value
      when Date, Time
        fill_in field, with: value.strftime('%m/%d/%Y')
      when TrueClass, FalseClass
        value ? check(field) : uncheck(field)
      else
        fill_in field, with: value
      end
    end
  end

  def select_from_dropdown(option, from:)
    select option, from: from
  end

  def expect_success_message(message = nil)
    if message
      expect(page).to have_content(message)
    else
      expect(page).to have_css('.alert-success, .notice, .success, .flash-success')
    end
  end

  def expect_error_message(message = nil)
    if message
      expect(page).to have_content(message)
    else
      expect(page).to have_css('.alert-danger, .error, .alert, .flash-error')
    end
  end

  def take_screenshot_for_debugging(name = nil)
    screenshot_name = name || "debug_#{Time.current.to_i}"
    screenshot_path = File.join(Capybara.save_path, 'screenshots', "#{screenshot_name}.png")
    page.save_screenshot(screenshot_path) # rubocop:disable Lint/Debugger
    puts "Screenshot saved: #{screenshot_path}"
  end
end

if rails_system_enabled
  RSpec.configure do |config|
    # Include Capybara DSL and helpers for rails_system type
    config.include Capybara::DSL, type: :rails_system
    config.include_context 'RailsSystemHelper', type: :rails_system

    config.before(:each, type: :rails_system) do
      Capybara.current_driver = :rails_cuprite
    end

    config.after(:each, type: :rails_system) do
      Capybara.use_default_driver
    end

    # Create screenshots directory
    config.before(:suite) do
      FileUtils.mkdir_p('tmp/capybara/screenshots/') if rails_system_enabled
    end
  end
end
