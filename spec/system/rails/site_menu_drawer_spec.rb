###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Below the on-canvas breakpoint the site menu is a drawer opened from the
# header's hamburger (site_menu_controller.js). Escape closes it and returns
# focus to the hamburger; a click outside it closes it.
RSpec.feature 'site menu drawer', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:user) { create(:acl_user) }

  # The drawer breakpoint for the default (md) layout is lg (992px).
  let(:drawer_window_size) { [800, 800] }
  let(:default_window_size) { [1200, 800] }

  let(:hamburger_selector) { 'a[aria-label="Site Navigation"]' }

  before do
    sign_in_user(user)
    page.current_window.resize_to(*drawer_window_size)
    visit root_path
    wait_for_site_menu_controller
  end

  after do
    page.current_window.resize_to(*default_window_size)
  end

  # The esbuild bundle starts Stimulus only after Sprockets' jQuery loads, so a
  # click before then would follow the hamburger's href="#" instead.
  def wait_for_site_menu_controller
    page.document.synchronize do
      connected = page.evaluate_script(<<~JS)
        !!window.Stimulus?.getControllerForElementAndIdentifier(document.body, 'site-menu')
      JS
      raise Capybara::ExpectationNotMet, 'site-menu controller not connected' unless connected
    end
  end

  def open_drawer
    find(hamburger_selector).click

    expect(page).to have_css('body.menu-open')
    expect(page).to have_css("#{hamburger_selector}[aria-expanded='true']")
  end

  def expect_drawer_closed
    expect(page).to have_no_css('body.menu-open')
    expect(page).to have_css("#{hamburger_selector}[aria-expanded='false']")
  end

  describe 'drawer', js: true do
    it 'closes on Escape and returns focus to the hamburger' do
      open_drawer

      find('body').send_keys(:escape)

      expect_drawer_closed
      focused_label = page.evaluate_script('document.activeElement.getAttribute("aria-label")')
      expect(focused_label).to eq('Site Navigation')
    end

    it 'closes on a click outside the drawer' do
      open_drawer

      find('.o-header--page__sub-title').click

      expect_drawer_closed
    end

    it 'closes when the hamburger is clicked again' do
      open_drawer

      find(hamburger_selector).click

      expect_drawer_closed
    end
  end
end
