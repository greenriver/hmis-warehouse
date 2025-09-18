###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

# Use puts for immediate output since Rails.logger might not be ready
if ENV['RUN_SYSTEM_TESTS'] || ENV['RUN_RAILS_SYSTEM_TESTS']
  puts '=== E2E Setup Debug ==='
  puts "RUN_SYSTEM_TESTS: #{ENV['RUN_SYSTEM_TESTS'].inspect}"
  puts "RUN_RAILS_SYSTEM_TESTS: #{ENV['RUN_RAILS_SYSTEM_TESTS'].inspect}"
  puts "All ENV vars containing 'SYSTEM': #{ENV.select { |k, _v| k.include?('SYSTEM') }.inspect}"
end

if ENV['RUN_SYSTEM_TESTS']
  Rails.logger.info '=== Loading E2E Tests Setup ==='
  Rails.logger.info "CHROME_URL: #{ENV['CHROME_URL']}"

  require_relative './e2e_tests'

  begin
    Rails.logger.info '=== Performing E2E Setup ==='
    E2eTests::Setup.perform
    Rails.logger.info '=== E2E Setup completed successfully ==='
  rescue StandardError => e
    Rails.logger.error "=== E2E Setup failed: #{e.message} ==="
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    raise
  end

  Capybara.default_driver = E2eTests::DRIVER_NAME
  Rails.logger.info "=== Set default driver to #{E2eTests::DRIVER_NAME} ==="
else
  puts '=== E2E Setup SKIPPED - RUN_SYSTEM_TESTS not set ==='
  puts 'This means system tests will fail with nil browser objects'
end

# from user factory
DEFAULT_USER_PASSWORD = Digest::SHA256.hexdigest('abcd1234abcd1234')

# test helper methods
RSpec.shared_context 'SystemSpecHelper' do
  def sign_in(user, password: DEFAULT_USER_PASSWORD)
    # this should go into before-each but that seems to hang up some tests
    visit('/')

    fill_in 'Email Address', with: user.email
    fill_in 'Password', with: password
    click_button('Sign In')
    assert_text user.full_name # user's name should appear in the header

    # Refresh page to address intermittent "_cuprite is not defined" failures on CI https://github.com/rubycdp/cuprite/issues/219
    page.driver.wait_for_network_idle
    page.driver.refresh
    assert_text user.full_name
  end

  def sign_out
    find('#userMenuToggle').click
    # FIXME: sign out button needs a11y
    find('span', text: 'Sign Out').click
  end

  def set_hidden_field_value(id, value)
    find_field(id, type: :hidden).set(value)
  end

  def mui_radio_choose(choice, from:)
    scroll_to("[aria-label='#{from}']")
    within("[aria-label='#{from}']") do
      choose(choice)
    end
  end

  def mui_radio_value_for(radio_label)
    # This is a custom helper for getting the currently checked value from a MUI radio group.
    # It's painfully slow, but correctly returns nil, when the group doesn't have a value selected.
    # It should only be used for radio buttons since it doesn't correctly handle multi-select (checkboxes).
    # `visible: :any` works around MUI applying opacity 0 to the actual radio input.
    find("[aria-label='#{radio_label}']").all('label span[data-checked="true"] input[type="radio"]', visible: :any).first&.value
  end

  def mui_select(choice, from:)
    label = find('label', text: from)
    scroll_to(label, align: :center)
    id = label['for']
    find("[id='#{id}']").click
    find('li[role=option]', text: choice).trigger(:click)
  end

  def mui_select_value_for(select_label)
    label = find('label', text: select_label)
    id = label['for']
    find("[id='#{id}']").value
  end

  def mui_table_select(choice, row:, column:, from: nil)
    row_label = from ? from.find('td', text: row) : find('td', text: row)
    scroll_to(row_label, align: :center)
    column_label = from ? from.find('th', text: column) : find('th', text: column)
    input_selector = "[aria-labelledby='#{row_label['id']} #{column_label['id']}']"
    if choice.present?
      find(input_selector).click
      find('li[role=option]', text: choice).click
    else
      find("#{input_selector} + div > button[aria-label='Clear']").click
    end
  end

  def mui_table_expect(expected, row_index:, column_header:, from:)
    header_cells = from.all('thead th')
    column_index = header_cells.find_index { |cell| !!cell.text.match(column_header) }
    expect(column_index).not_to be_nil

    rows = from.all('tbody tr')
    row = rows[row_index]
    cell = row.all('td')[column_index]
    expect(cell.text).to match(expected)
  end

  def mui_table_element_for(row:, column:)
    row_label = find('td', text: row)
    column_label = find('th', text: column)
    find("[aria-labelledby='#{row_label['id']} #{column_label['id']}']")
  end

  def mui_date_select(label, date:)
    field = find("[aria-label='#{label}']")
    scroll_to(field, align: :center)
    field.click
    # This key sequence is a bit silly, but Capybara's field.set and field.fill_in don't work for MUI datepicker
    if date.present?
      field.native.send_keys(:left, :left, :backspace, date.strftime('%m/%d/%Y'), :tab) # tab to trigger blur
    else
      field.native.send_keys(:backspace, :left, :backspace, :left, :backspace, :tab)
    end
  end

  def mui_expect_selected_tab(tab_selector)
    expect(page).to have_css("#{tab_selector}[role=\"tab\"][aria-selected=\"true\"]")
  end

  def mui_click_menu_item(label)
    find("[role='menuitem']", text: label).click
  end

  def mui_click_checkbox(label)
    checkbox_label = find('label', text: label, match: :prefer_exact)
    checkbox_label.find('input[type="checkbox"]', visible: :all).click
  end

  def with_hidden
    last_value = Capybara.ignore_hidden_elements
    begin
      Capybara.ignore_hidden_elements = false
      yield
    ensure
      Capybara.ignore_hidden_elements = last_value
    end
  end

  def browser
    page.driver.browser
  end
end

# Browser health monitoring and management
class BrowserHealthManager
  @test_count = 0
  @browser_restarts = 0
  @last_memory_check = Time.current

  class << self
    attr_accessor :test_count, :browser_restarts, :last_memory_check

    def increment_test_count
      @test_count += 1
    end

    def should_restart_browser?
      # Restart every 25 tests to prevent memory buildup
      restart_interval = ENV.fetch('BROWSER_RESTART_INTERVAL', 25).to_i
      @test_count > 0 && (@test_count % restart_interval) == 0
    end

    def get_memory_info # rubocop:disable Naming/AccessorMethodName
      return {} unless File.exist?('/proc/meminfo')

      meminfo = {}
      File.readlines('/proc/meminfo').each do |line|
        key, value = line.split(':')
        next unless value

        # Convert to MB for readability
        meminfo[key.strip] = value.strip.split.first.to_i / 1024 if value.include?('kB')
      end
      meminfo
    rescue StandardError => e
      Rails.logger.warn "Could not read memory info: #{e.message}"
      {}
    end

    def log_system_stats
      return unless (@test_count % 10) == 0 || (Time.current - @last_memory_check) > 60

      @last_memory_check = Time.current
      memory_info = get_memory_info

      return unless memory_info.any?

      Rails.logger.info "=== System Stats (Test #{@test_count}) ==="
      Rails.logger.info "Memory Available: #{memory_info['MemAvailable']}MB" if memory_info['MemAvailable']
      Rails.logger.info "Memory Free: #{memory_info['MemFree']}MB" if memory_info['MemFree']
      Rails.logger.info "Buffers: #{memory_info['Buffers']}MB" if memory_info['Buffers']
      Rails.logger.info "Cached: #{memory_info['Cached']}MB" if memory_info['Cached']
      Rails.logger.info "Browser restarts so far: #{@browser_restarts}"
    end

    def browser_health_check
      return false unless Capybara.current_session&.driver.respond_to?(:browser)

      browser = Capybara.current_session.driver.browser
      return false unless browser

      # Try a simple command to test if browser is responsive
      begin
        browser.evaluate('true')
        true
      rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError
        false
      rescue StandardError => e
        Rails.logger.warn "Browser health check failed: #{e.message}"
        false
      end
    end
  end
end

RSpec.configure do |config|
  if !ENV['RUN_SYSTEM_TESTS']
    config.before(:each, type: :system) do
      skip 'Skipping system tests because RUN_SYSTEM_TESTS is not set'
    end
    next
  end

  config.include E2eTests::Helpers, type: :system
  config.include_context 'SystemSpecHelper', type: :system

  config.prepend_before(:each, type: :system) do
    # Increment test counter and check system health
    BrowserHealthManager.increment_test_count
    BrowserHealthManager.log_system_stats

    # Check if we should proactively restart the browser
    if BrowserHealthManager.should_restart_browser?
      Rails.logger.warn "=== Proactive browser restart after #{BrowserHealthManager.test_count} tests ==="
      begin
        force_browser_restart
        BrowserHealthManager.browser_restarts += 1
        Rails.logger.info 'Proactive browser restart completed successfully'
      rescue StandardError => e
        Rails.logger.error "Proactive browser restart failed: #{e.message}"
        # Continue with test anyway - the retry mechanism will handle failures
      end
    end

    # Health check before each test
    unless BrowserHealthManager.browser_health_check
      Rails.logger.warn 'Browser health check failed, attempting restart before test'
      begin
        force_browser_restart
        BrowserHealthManager.browser_restarts += 1
      rescue StandardError => e
        Rails.logger.error "Pre-test browser restart failed: #{e.message}"
      end
    end

    # Use JS driver always
    driven_by E2eTests::DRIVER_NAME
  end

  # Make urls in mailers contain the correct server host.
  # It's required for testing links in emails (e.g., via capybara-email).
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host

    max_retries = ENV.fetch('SYSTEM_TEST_RETRIES', 2).to_i
    retry_count = 0

    begin
      ex.run
    rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError, NoMethodError => e
      # Check if this is a browser-related NoMethodError
      if e.is_a?(NoMethodError) && !e.message.include?('reset')
        raise # Re-raise if it's not a browser reset issue
      end

      retry_count += 1
      if retry_count <= max_retries
        Rails.logger.warn "System test failed with browser error (attempt #{retry_count}/#{max_retries + 1}): #{e.message}"

        # Force complete browser restart
        force_browser_restart

        sleep(3) # Longer pause before retry
        retry
      else
        Rails.logger.error "System test failed after #{max_retries} retries: #{e.message}"
        raise
      end
    ensure
      Rails.application.default_url_options[:host] = was_host
    end
  end

  # Helper method to force complete browser restart
  def force_browser_restart
    Rails.logger.warn 'Forcing complete browser restart'

    # Log memory info before restart
    memory_info = BrowserHealthManager.get_memory_info
    Rails.logger.info "Memory before restart - Available: #{memory_info['MemAvailable']}MB, Free: #{memory_info['MemFree']}MB" if memory_info.any?

    # Debug current browser state
    begin
      Rails.logger.info "Current session: #{Capybara.current_session.inspect}"
      Rails.logger.info "Current driver: #{Capybara.current_session.driver.inspect}"
      Rails.logger.info "Browser object: #{Capybara.current_session.driver.browser.inspect}" if Capybara.current_session.driver.respond_to?(:browser)
    rescue StandardError => e
      Rails.logger.warn "Could not inspect current state: #{e.message}"
    end

    begin
      # Try to quit the current driver cleanly
      if Capybara.current_session&.driver.respond_to?(:quit)
        Rails.logger.info 'Attempting to quit current driver'
        Capybara.current_session.driver.quit
        Rails.logger.info 'Driver quit successfully'
      end
    rescue StandardError => e
      Rails.logger.warn "Could not quit driver cleanly: #{e.message}"
    end

    begin
      # Clear all sessions
      Rails.logger.info 'Attempting to reset sessions'
      Capybara.reset_sessions!
      Rails.logger.info 'Sessions reset successfully'
    rescue StandardError => e
      Rails.logger.warn "Could not reset sessions: #{e.message}"
    end

    # Force garbage collection to clean up dead objects
    Rails.logger.info 'Running garbage collection'
    GC.start

    # Recreate the session by visiting a simple page
    begin
      Rails.logger.info 'Attempting to create new browser session'
      # This will force creation of a new browser instance
      visit('about:blank')
      Rails.logger.info 'Successfully restarted browser'

      # Log memory info after restart
      memory_info = BrowserHealthManager.get_memory_info
      Rails.logger.info "Memory after restart - Available: #{memory_info['MemAvailable']}MB, Free: #{memory_info['MemFree']}MB" if memory_info.any?

      # Debug new browser state
      Rails.logger.info "New session: #{Capybara.current_session.inspect}"
      Rails.logger.info "New driver: #{Capybara.current_session.driver.inspect}"
      Rails.logger.info "New browser: #{Capybara.current_session.driver.browser.inspect}" if Capybara.current_session.driver.respond_to?(:browser)
    rescue StandardError => e
      Rails.logger.error "Failed to restart browser: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"

      # Last resort: try to completely reinitialize Capybara
      Rails.logger.warn 'Attempting last resort: complete Capybara reinitialization'
      begin
        # Force re-registration of the driver with fallback to local Chrome
        Rails.logger.warn 'Re-checking Chrome connection for recovery'
        chrome_connected = E2eTests::RemoteChrome.connected?
        Rails.logger.info "Chrome connected during recovery: #{chrome_connected}"

        Capybara.register_driver(E2eTests::DRIVER_NAME) do |app|
          driver_options = {
            extensions: ["#{Rails.root}/spec/assets/disable_transitions.js"],
            window_size: [1200, 1600],
            browser_options: { 'no-sandbox' => nil },
            headless: ENV.fetch('CI', 'true') == 'true',
            js_errors: true,
            timeout: ENV.fetch('FERRUM_DEFAULT_TIMEOUT', 60).to_i,
            process_timeout: ENV.fetch('FERRUM_PROCESS_TIMEOUT', 90).to_i,
            pending_connection_errors: false,
          }

          # Only use remote Chrome if it's actually connected
          if chrome_connected
            Rails.logger.info 'Using remote Chrome for recovery'
            driver_options.merge!(E2eTests::RemoteChrome.options)
          else
            Rails.logger.warn 'Remote Chrome unavailable, falling back to local Chrome'
            # Add additional browser options for local Chrome stability
            driver_options[:browser_options].merge!({
                                                      'disable-dev-shm-usage' => nil,
                                                      'disable-gpu' => nil,
                                                      'disable-extensions' => nil,
                                                    })
          end

          ::Capybara::Cuprite::Driver.new(app, **driver_options)
        end

        # Force switch to the driver
        driven_by E2eTests::DRIVER_NAME

        # Try visiting a simple page again
        visit('about:blank')
        Rails.logger.info 'Successfully recovered with complete reinitialization'
      rescue StandardError => recovery_error
        Rails.logger.error "Complete recovery failed: #{recovery_error.message}"
        raise e # Raise the original error
      end
    end
  end

  # Add better cleanup handling
  config.after(:each, type: :system) do |example|
    # Take screenshot on failure for debugging
    if example.exception
      begin
        page.save_screenshot # rubocop:disable Lint/Debugger
      rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError, NoMethodError => e
        Rails.logger.warn "Could not take screenshot due to browser error: #{e.message}"
      end
    end

    # Safe cleanup that handles dead browsers
    begin
      Capybara.reset_sessions!
    rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError, NoMethodError => e
      Rails.logger.warn "Browser cleanup failed: #{e.message}"
      begin
        Capybara.current_session.driver.quit if Capybara.current_session&.driver.respond_to?(:quit)
      rescue StandardError => cleanup_error
        Rails.logger.warn "Could not quit driver cleanly: #{cleanup_error.message}"
      end
    end
  end
end
