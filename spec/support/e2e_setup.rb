###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

if ENV['RUN_SYSTEM_TESTS']
  require_relative './e2e_tests'
  E2eTests::Setup.perform
  Capybara.default_driver = E2eTests::DRIVER_NAME
end

# from user factory
DEFAULT_USER_PASSWORD = Digest::SHA256.hexdigest('abcd1234abcd1234')

# test helper methods
RSpec.shared_context 'SystemSpecHelper' do
  # Sign in a user for system specs using JWT authentication.
  #
  # This replaces the old Devise-based login form flow with JWT-based authentication.
  # Instead of filling in a login form (which no longer exists with OAuth2-proxy),
  # we inject a JWT token into the session and navigate to the application.
  #
  # @param user [User, Hmis::User] The user to sign in
  # @param _password [String] Unused, kept for backward compatibility
  def sign_in(user, _password: DEFAULT_USER_PASSWORD)
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

    # Stub User.find_from_jwt to return the user for our mock token
    # Note: HMIS controllers also use this - they call User.find_from_jwt then cast to Hmis::User
    allow(User).to receive(:find_from_jwt).and_wrap_original do |original_method, helper|
      helper == jwt_helper ? user : original_method.call(helper)
    end

    # Create authentication source upfront to avoid extra queries during request
    # This prevents ensure_authentication_source from running during the request
    user.user_authentication_sources.find_or_create_by!(
      connector_id: 'test',
      connector_user_id: user.id.to_s,
    ) do |auth_source|
      auth_source.enabled = true
    end
    user.update_column(:last_connector_id, 'test') if user.last_connector_id != 'test'

    # Visit the application first (required to set cookies)
    visit('/')

    # Set the test JWT token in a cookie that CurrentUser will read
    # This bypasses oauth2-proxy which isn't running in tests
    # E2E tests use Cuprite driver which has a different cookie API than Selenium
    page.driver.set_cookie('test_jwt_token', mock_token, path: '/', httponly: false, secure: false)

    # Navigate to home page (now authenticated)
    visit('/')

    # Wait for page to load and verify user is signed in
    page.driver.wait_for_network_idle
    assert_text user.full_name # user's name should appear in the header
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
    option = mui_find_select_option(choice, from: from)
    option.trigger(:click)
  end

  def mui_find_select_option(choice, from:)
    label = find('label', text: from)
    scroll_to(label, align: :center)
    id = label['for']
    find("[id='#{id}']").click
    find('li[role=option]', text: choice)
  end

  # Given the label for a MUI select (dropdown) element, get the choices in the list
  def mui_select_option_list(from:)
    label_element = find('label', text: from)
    scroll_to(label_element, align: :center)
    id = label_element['for']
    select_element = find("[id='#{id}']")

    # Open the dropdown to make options visible
    select_element.click

    # Get all the option choices
    choices = all('li[role=option]').map(&:text)

    # Close the dropdown
    find('body').send_keys(:escape)

    choices
  end

  def mui_clear_select(from:)
    label = find('label', text: from)
    scroll_to(label, align: :center)
    input_id = label['for']
    find("[id='#{input_id}'] + div > button[aria-label='Clear']", visible: :all).trigger(:click)
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
    # Wait for table to have rows before proceeding
    expect(from).to have_css('tbody tr', minimum: row_index + 1)

    header_cells = from.all('thead th')
    column_index = header_cells.find_index { |cell| !!cell.text.match(column_header) }
    expect(column_index).not_to be_nil

    rows = from.all('tbody tr')
    cell = rows[row_index].all('td')[column_index]
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

  # Impersonate the given user by making an API call to the impersonation endpoint using JS fetch,
  # instead of navigating to the Admin page and impersonating the user manually.
  # (impersonate_hmis_user can't be used directly outside of the impersonations controller)
  def with_user_impersonated(user_id)
    user = Hmis::User.find(user_id)

    # Make a POST request to start impersonation using JavaScript fetch
    page.execute_script(<<~JS)
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
      return fetch('/hmis/impersonations', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
        },
        body: JSON.stringify({ user_id: #{user.id} })
      }).then(async (r) => {
        const body = await r.text();
        return { ok: r.ok, status: r.status, body: body };
      });
    JS

    visit current_path # reload the page
    expect(page).to have_content("Acting as #{user.full_name}")

    begin
      yield
    ensure
      # Stop impersonating by making a DELETE request
      page.execute_script(<<~JS)
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        return fetch('/hmis/impersonations', {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken,
          }
        }).then(r => r.ok);
      JS

      visit current_path # reload the page
      expect(page).not_to have_content("Acting as #{user.full_name}")
    end
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
