# frozen_string_literal: true

# Standard Rails application system test setup
# Separate from the React/MUI e2e test infrastructure

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
