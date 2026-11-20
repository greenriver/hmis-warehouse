###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.feature 'Popovers', type: :rails_system do
  include_context 'RailsSystemHelper'
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }

  before { Collection.maintain_system_groups }

  # Counts popovers after a pause, since a popover that closes itself shortly after rendering still satisfies an immediate check.
  def popover_count_after(milliseconds)
    page.evaluate_async_script(<<~JS, milliseconds)
      const [milliseconds, done] = arguments
      setTimeout(() => done(document.querySelectorAll('.popover').length), milliseconds)
    JS
  end

  describe 'client information popover on a report drilldown', js: true do
    let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
    let!(:report_definition) { create(:touch_point_report, url: 'hmis_data_quality_tool/warehouse_reports/reports', name: 'HMIS Data Quality Tool') }
    let!(:project) { create_project(project_type: 1) }
    let!(:dq_report) { HmisDataQualityTool::Report.create!(user_id: user.id, report_name: 'HMIS Data Quality Tool', options: {}, question_names: []) }
    let!(:source) { create_client_with_warehouse_link(first_name: 'Zzpopfirst', last_name: 'Zzpoplast') }

    before do
      create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
      # The drilldown row carries its own name; a different value keeps the popover's name attributable to the API.
      HmisDataQualityTool::Client.create!(
        report_id: dq_report.id,
        client_id: source.id,
        destination_client_id: source.destination_client.id,
        personal_id: source.PersonalID,
        data_source_id: source.data_source_id,
        first_name: 'Zzrowfirst',
        last_name: 'Zzrowlast',
        ch_at_most_recent_entry: true,
      )
      collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
      setup_access_control(user, role, collection)
      sign_in_user(user)
    end

    it 'shows the client table returned by the client API' do
      visit items_hmis_data_quality_tool_warehouse_reports_report_path(dq_report, key: 'client_ch_most_recent')

      find('a.btn-sm > i.icon-info').click

      # Not `within('.popover')`: the popover element is replaced when the API response arrives.
      expect(page).to have_css('.popover .popover-header', text: 'Client Information')
      expect(page).to have_css('.popover table td', text: source.PersonalID)
      expect(page).to have_css('.popover table td', text: 'Zzpopfirst')
      expect(page).to have_css('.popover table td', text: 'Zzpoplast')
      expect(popover_count_after(500)).to eq(1)
    end
  end

  describe 'focus-triggered popover with HTML content', js: true do
    let!(:role) { create(:role, can_edit_roles: true) }

    before do
      setup_access_control(user, role, collection)
      sign_in_user(user)
    end

    it 'renders the link in the access control popover' do
      visit admin_access_overviews_path

      click_link 'access control'

      expect(page).to have_css('.popover.access-overview-popover')
      within('.popover') do
        expect(page).to have_css('.popover-header', text: 'Access Control')
        expect(page).to have_link('Manage Access Controls', href: admin_access_controls_path)
      end
    end
  end

  describe 'focus trigger', js: true do
    let!(:role) { create(:role, can_edit_roles: true) }

    before do
      setup_access_control(user, role, collection)
      sign_in_user(user)
    end

    it 'opens when the element is focused and closes when focus moves away' do
      visit admin_access_overviews_path

      page.execute_script("document.querySelector('a[data-bs-toggle=\"popover\"]').focus()")
      expect(page).to have_css('.popover .popover-header', text: 'Access Control')

      page.execute_script('document.activeElement.blur()')
      expect(page).to have_no_css('.popover')
    end
  end

  describe 'triggers added after page load', js: true do
    let!(:role) { create(:role, can_edit_roles: true) }

    before do
      setup_access_control(user, role, collection)
      sign_in_user(user)
      visit admin_access_overviews_path
    end

    # No page renders these attribute combinations, so the triggers are injected into a real page.
    def add_trigger(id, attributes)
      page.execute_script(<<~JS, id, attributes)
        const [id, attributes] = arguments
        const button = document.createElement('button')
        button.id = id
        button.type = 'button'
        button.textContent = id
        button.setAttribute('data-bs-toggle', 'popover')
        Object.entries(attributes).forEach(([name, value]) => button.setAttribute(name, value))
        document.body.prepend(button)
      JS
    end

    it 'opens a trigger inserted after load' do
      add_trigger('late-trigger', 'data-bs-title' => 'Late title', 'data-bs-content' => 'Zzlatebody')

      find('#late-trigger').click

      expect(page).to have_css('.popover .popover-header', text: 'Late title')
      expect(page).to have_css('.popover .popover-body', text: 'Zzlatebody')
    end

    it 'opens an explicit click trigger on click and renders its table' do
      add_trigger(
        'click-trigger',
        'data-bs-trigger' => 'click',
        'data-bs-html' => 'true',
        'data-bs-content' => '<table><tr><td>Zzclickcell</td></tr></table>',
      )

      find('#click-trigger').click

      expect(page).to have_css('.popover table td', text: 'Zzclickcell')
    end

    it 'opens a hover trigger on hover and closes it when the pointer leaves' do
      add_trigger('hover-trigger', 'data-bs-trigger' => 'hover', 'data-bs-content' => 'Zzhoverbody')

      find('#hover-trigger').hover
      expect(page).to have_css('.popover .popover-body', text: 'Zzhoverbody')

      find('h1').hover
      expect(page).to have_no_css('.popover')
    end

    it 'removes disallowed markup but keeps table markup' do
      add_trigger(
        'sanitize-trigger',
        'data-bs-html' => 'true',
        'data-bs-content' => '<img src="x" onerror="window.__popoverXss=1"><script>window.__popoverXss=2</script><table><tr><td>Zzcell</td></tr></table>',
      )

      find('#sanitize-trigger').click

      expect(page).to have_css('.popover table td', text: 'Zzcell')
      expect(page).to have_no_css('.popover script', visible: :all)
      expect(page).to have_no_css('.popover [onerror]', visible: :all)
      expect(page.evaluate_script('window.__popoverXss')).to be_nil
    end

    it 'shows an error for a client the user cannot load and fetches again on the next show' do
      path = api_client_path(0)
      page.execute_script(<<~JS, path)
        const [path] = arguments
        window.__popoverFetches = 0
        const originalFetch = window.fetch
        window.fetch = (url, options) => {
          if (String(url).includes(path)) window.__popoverFetches += 1
          return originalFetch(url, options)
        }
      JS
      add_trigger('url-trigger', 'data-bs-title' => 'Client', 'data-bs-url' => path, 'data-bs-html' => 'true')

      find('#url-trigger').click
      expect(page).to have_css('.popover .popover-body', text: 'Unable to load')
      expect(page.evaluate_script('window.__popoverFetches')).to eq(1)

      find('#url-trigger').click
      expect(page).to have_no_css('.popover')
      find('#url-trigger').click
      expect(page).to have_css('.popover .popover-body', text: 'Unable to load')
      expect(page.evaluate_script('window.__popoverFetches')).to eq(2)
      expect(popover_count_after(500)).to eq(1)
    end

    it 'opens a URL trigger that has no title or content attributes' do
      add_trigger('bare-url-trigger', 'data-bs-url' => api_client_path(0), 'data-bs-html' => 'true')

      find('#bare-url-trigger').click

      expect(page).to have_css('.popover .popover-body', text: 'Unable to load')
    end

    it 'fetches once when the pointer leaves and re-enters a hover trigger while the fetch is pending' do
      path = api_client_path(0)
      page.execute_script(<<~JS, path)
        const [path] = arguments
        window.__popoverFetches = 0
        const originalFetch = window.fetch
        window.fetch = (url, options) => {
          if (!String(url).includes(path)) return originalFetch(url, options)
          window.__popoverFetches += 1
          return new Promise(resolve => { window.__releaseFetch = () => resolve(originalFetch(url, options)) })
        }
      JS
      add_trigger('slow-trigger', 'data-bs-trigger' => 'hover', 'data-bs-url' => path, 'data-bs-html' => 'true')

      find('#slow-trigger').hover
      find('h1').hover
      find('#slow-trigger').hover
      expect(page.evaluate_script('window.__popoverFetches')).to eq(1)

      page.execute_script('window.__releaseFetch()')
      expect(page).to have_css('.popover .popover-body', text: 'Unable to load')
      expect(popover_count_after(500)).to eq(1)
    end
  end

  describe 'file tag note popover', js: true do
    let!(:warehouse_client) { create :authoritative_warehouse_client }
    let!(:client) { warehouse_client.destination }
    let!(:tag) { create :available_file_tag, name: 'Zztagname', note: 'Zztagnote' }
    let!(:role) { create(:role, can_manage_client_files: true, can_see_own_file_uploads: true, can_search_own_clients: true) }

    before do
      collection.set_viewables({ data_sources: [warehouse_client.source.data_source_id] })
      setup_access_control(user, role, collection)
      sign_in_user(user)
    end

    it 'shows the tag name and note when the tag is selected' do
      visit new_client_file_path(client)

      find('label', text: 'Zztagname').click

      expect(page).to have_css('.popover .popover-header', text: 'Zztagname')
      expect(page).to have_css('.popover .popover-body', text: 'Zztagnote')
    end
  end
end
