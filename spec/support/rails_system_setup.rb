# frozen_string_literal: true

# Standard Rails application system test setup
# Separate from the React/MUI e2e test infrastructure

# Enable by passing RUN_RAILS_SYSTEM_TESTS
rails_system_enabled = ENV['RUN_RAILS_SYSTEM_TESTS']

if rails_system_enabled
  require 'capybara/cuprite'
  require 'socket'

  # Configure Rails to serve assets properly in system tests
  ENV['RAILS_SERVE_STATIC_FILES'] = 'true'

  # Configure Capybara for standard Rails testing
  Capybara.configure do |config|
    config.default_max_wait_time = ENV.fetch('FERRUM_DEFAULT_TIMEOUT', 60).to_i # Configurable to match driver timeout
    config.default_normalize_ws = true
    config.ignore_hidden_elements = true
    config.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')
  end

  # Helper module for remote Chrome connection (for HMIS system tests only)
  module RailsRemoteChrome
    def self.url
      ENV['CHROME_URL']
    end

    def self.port
      URI.parse(url).yield_self(&:port) if url
    end

    def self.host
      URI.parse(url).yield_self(&:host) if url
    end

    def self.options
      connected? ? { url: url } : {}
    end

    def self.connected?
      if url.nil?
        false
      else
        Socket.tcp(host, port, connect_timeout: 10).close
        true
      end
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
      false
    end
  end

  # Register HMIS system test driver - uses remote Chrome if available (for type: :system)
  remote_options = RailsRemoteChrome.options

  Capybara.register_driver :rails_cuprite do |app|
    driver_options = {
      window_size: [1200, 800],
      headless: ENV.fetch('CI', 'true') == 'true',
      js_errors: false, # More lenient for standard Rails apps
      # logger: STDOUT, # Uncomment this for more verbose logging of everything the browser is doing
      timeout: ENV.fetch('FERRUM_DEFAULT_TIMEOUT', 60).to_i,           # Configurable timeout for slow asset loading
      process_timeout: ENV.fetch('FERRUM_PROCESS_TIMEOUT', 90).to_i,   # Configurable process timeout
      pending_connection_errors: false, # Ignore pending connection errors
      slowmo: ENV['CI'] ? 0 : 0.05, # Slight delay between actions in CI to improve stability
      browser_options: {
        'no-sandbox' => nil,
        'disable-gpu' => nil,
        'disable-dev-shm-usage' => nil,
        'disable-extensions' => nil,
        'disable-background-timer-throttling' => nil,
        'disable-backgrounding-occluded-windows' => nil,
        'disable-renderer-backgrounding' => nil,
        'disable-features' => 'VizDisplayCompositor',
        'disable-ipc-flooding-protection' => nil,
        'disable-web-security' => nil,
        'ignore-certificate-errors' => nil,
        'ignore-ssl-errors' => nil,
        'ignore-certificate-errors-spki-list' => nil,
        'ignore-certificate-errors-ssl' => nil,
      },
    }

    # Merge remote Chrome options if available (HMIS system tests only)
    driver_options.merge!(remote_options)

    Capybara::Cuprite::Driver.new(app, **driver_options)
  end

  # Register Rails warehouse system test driver - local Chrome only (for type: :rails_system)
  Capybara.register_driver :rails_warehouse_cuprite do |app|
    Capybara::Cuprite::Driver.new(
      app,
      window_size: [1200, 800],
      headless: ENV.fetch('CI', 'true') == 'true',
      js_errors: false, # More lenient for standard Rails apps
      timeout: ENV.fetch('FERRUM_DEFAULT_TIMEOUT', 60).to_i,
      process_timeout: ENV.fetch('FERRUM_PROCESS_TIMEOUT', 90).to_i,
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
      # Explicitly do NOT use remote Chrome - force local browser
    )
  end

  Capybara.default_driver = :rails_cuprite
  Capybara.javascript_driver = :rails_cuprite

  # Add RSpec configuration for better error handling - ONLY for HMIS system tests (type: :system)
  RSpec.configure do |config|
    config.before(:each, type: :system) do
      # Reset driver before each test to ensure clean state
      Capybara.reset_sessions!
    end

    config.after(:each, type: :system) do |example|
      # Take screenshot on failure for debugging
      if example.exception && page.driver.browser.present?
        begin
          page.save_screenshot # rubocop:disable Lint/Debugger
        rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError => e
          Rails.logger.warn "Could not take screenshot due to browser error: #{e.message}"
        end
      end
    end

    # Retry system tests that fail due to browser connection issues
    config.around(:each, type: :system) do |example|
      max_retries = ENV.fetch('SYSTEM_TEST_RETRIES', 2).to_i
      retry_count = 0

      begin
        example.run
      rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError => e
        retry_count += 1
        if retry_count <= max_retries
          Rails.logger.warn "System test failed with browser error (attempt #{retry_count}/#{max_retries + 1}): #{e.message}"
          # Reset everything and try again
          Capybara.reset_sessions!
          sleep(1) # Brief pause before retry
          retry
        else
          Rails.logger.error "System test failed after #{max_retries} retries: #{e.message}"
          raise
        end
      end
    end
  end
end

# Password from existing user factory
RAILS_SYSTEM_DEFAULT_PASSWORD = Digest::SHA256.hexdigest('abcd1234abcd1234')

# Standard Rails system test helpers (for warehouse tests using type: :rails_system)
RSpec.shared_context 'RailsSystemHelper' do
  def sign_in_user(user, password: RAILS_SYSTEM_DEFAULT_PASSWORD)
    visit new_user_session_path

    fill_in 'Email', with: user.email
    fill_in 'Password', with: password
    click_button 'Sign In'

    # Check if sign in was successful - look for user name or absence of sign in form
    return true if page.has_content?(user.first_name) # Success - user name appears

    if page.has_content?('Sign In')
      # Still on sign in page - check for error messages
      if page.has_content?('Invalid') || page.has_content?('error')
        puts 'Sign in failed with error message'
      else
        puts 'Sign in failed - still on sign in page'
      end
      puts page.body if ENV['DEBUG_TESTS']
      false
    else
      # Signed in but user name not visible - might be in a different element
      puts 'Signed in successfully (user name not immediately visible)'
      true
    end
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

# Configure Rails warehouse system tests (type: :rails_system) to use local driver
if rails_system_enabled
  RSpec.configure do |config|
    config.include_context 'RailsSystemHelper', type: :rails_system

    config.before(:each, type: :rails_system) do
      # Use the warehouse cuprite driver (local Chrome only)
      driven_by :rails_warehouse_cuprite
      # Reset sessions for clean state
      Capybara.reset_sessions!
    end

    config.after(:each, type: :rails_system) do |example|
      # Take screenshot on failure for debugging
      if example.exception
        begin
          page.save_screenshot # rubocop:disable Lint/Debugger
        rescue StandardError => e
          Rails.logger.warn "Could not take screenshot: #{e.message}"
        end
      end
    end

    # Create screenshots directory
    config.before(:suite) do
      FileUtils.mkdir_p('tmp/capybara/screenshots/')
    end
  end
end
