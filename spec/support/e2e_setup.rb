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

# Suite-level HMIS JSON form seeding
module E2eSystemSuite
  def self.seed_hmis_json_forms!
    data_source = GrdaWarehouse::DataSource.find_or_create_by!(
      hmis: 'localhost',
      name: 'HMIS',
      short_name: 'HMIS',
      authoritative: true,
    )
    ::HmisUtil::JsonForms.seed_all(data_source_id: data_source.id)
  end
end

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
