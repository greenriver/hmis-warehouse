###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Proves that the headless browser, Ferrum, and Rails all agree on the timezone, so date
# defaults/comparisons in system tests don't drift by a day when CI runs near the UTC boundary.
# See spec/support/e2e_tests.rb (env: { 'TZ' => ... }) for the fix these tests guard.
RSpec.feature 'System test timezone alignment', type: :system do
  # Read the browser's IANA timezone identifier (what Chromium/ICU resolved it to).
  def browser_timezone
    page.evaluate_script('Intl.DateTimeFormat().resolvedOptions().timeZone')
  end

  # Read the browser's current local date as an ISO 'YYYY-MM-DD' string. The 'en-CA' locale is a
  # deliberate idiom for ISO formatting (YYYY-MM-DD) so it matches Ruby's Date#iso8601 below; it is
  # not about Canada. ('en-US' would give M/D/YYYY and never match.)
  def browser_current_date
    page.evaluate_script("new Date().toLocaleDateString('en-CA')")
  end

  # The browser's date must equal Rails' current date. Guard against the (vanishingly rare) case
  # of crossing local midnight between the two reads by accepting either side of the boundary.
  def expect_browser_date_to_match_rails
    before_date = Date.current
    actual = browser_current_date
    after_date = Date.current
    expect([before_date.iso8601, after_date.iso8601]).to include(actual)
  end

  it 'runs the browser in the same timezone as Rails (America/New_York in CI)' do
    visit '/' # any page will do; we only need a JS context

    # The core, deterministic guard: before the fix the browser resolved to UTC (its container's
    # system zone) while Rails uses America/New_York, so these identifiers differed on every run.
    expect(browser_timezone).to eq(Time.zone.tzinfo.identifier)

    expect_browser_date_to_match_rails
  end

  # Force Rails onto a zone that is currently on a *different calendar date than UTC*, launch a
  # browser configured for that same zone (via the same TZ-env mechanism as the fix), and prove
  # the test's "today" follows Rails rather than falling back to UTC.
  it 'uses the current date from Rails, not UTC, when the two are on different days' do
    # UTC+14 and UTC-12 are fixed-offset zones (no DST). At any instant at least one of them is on
    # a different calendar day than UTC, so this test is deterministic regardless of wall-clock.
    utc_today = Time.now.getutc.to_date
    zone = ['Pacific/Kiritimati', 'Etc/GMT+12'].find do |z|
      Time.find_zone!(z).now.to_date != utc_today
    end
    expect(zone).to be_present, 'expected one extreme zone to differ from UTC (should always hold)'

    driver_name = :cuprite_tz_probe
    Capybara.register_driver(driver_name) do |app|
      Capybara::Cuprite::Driver.new(
        app,
        headless: true,
        browser_path: ENV.fetch('CHROMIUM_PATH', '/usr/bin/chromium'),
        browser_options: { 'no-sandbox' => nil, 'disable-dev-shm-usage' => nil },
        env: { 'TZ' => zone }, # same mechanism as the real driver: set the browser's OS timezone
      )
    end

    Time.use_zone(zone) do
      Capybara.using_driver(driver_name) do
        visit '/'

        # The browser agrees with Rails' current date... (identifier equality is covered by the
        # first test; here we assert on dates because ICU may canonicalize an Etc/* zone name.)
        expect_browser_date_to_match_rails

        # ...and that date is genuinely NOT the UTC date, proving we aren't silently on UTC.
        expect(browser_current_date).not_to eq(Time.now.getutc.to_date.iso8601)
      end
    end
  end
end
