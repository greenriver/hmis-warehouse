if ENV['RUN_SYSTEM_TESTS']
  require_relative './e2e_tests'
  E2eTests::Setup.perform
  Capybara.default_driver = E2eTests::DRIVER_NAME
end

# test helper methods
RSpec.shared_context 'SystemSpecHelper' do
  # from user factory
  DEFAULT_USER_PASSWORD = Digest::SHA256.hexdigest('abcd1234abcd1234')

  def sign_in(user, password: DEFAULT_USER_PASSWORD)
    # this should go into before-each but that seems to hang up some tests
    visit('/')
    disable_transitions

    fill_in 'Email Address', with: user.email
    fill_in 'Password', with: password
    click_button('Sign In')

    page.driver.refresh # https://github.com/rubycdp/cuprite/issues/219
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

  def mui_select(choice, from:)
    label = find('label', text: from)
    scroll_to(label, align: :center)
    id = label['for']
    # we seem to have invalid ids such as "3.917A.1"
    # find("##{id}").click
    find("[id='#{id}']").click
    find('li[role=option]', text: choice).click
  end

  def mui_table_select(choice, row:, column:)
    row_label = find('td', text: row)
    scroll_to(row_label, align: :center)
    column_label = find('th', text: column)
    find("[aria-labelledby='#{row_label['id']} #{column_label['id']}']").click
    find('li[role=option]', text: choice).click
  end

  def mui_date_select(label, date:)
    field = find("[aria-label='#{label}']")
    scroll_to(field, align: :center)
    field.click
    # This key sequence is a bit silly, but Capybara's field.set and field.fill_in don't work for MUI datepicker
    field.native.send_keys(:left, :left, :backspace, date.strftime('%m/%d/%Y'))
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

  def disable_transitions
    @disable_transitions_js ||= File.read(Rails.root.join('spec/assets/disable_transitions.js'))
    browser.add_script_tag(content: @disable_transitions_js)
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
