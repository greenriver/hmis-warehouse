###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Per-form CSRF tokens', type: :rails_system do
  include_context 'RailsSystemHelper'
  include AccessControlSetup

  let!(:agency) { create :agency }
  let!(:role) { create :admin_role }
  let!(:user) { create :acl_user, agency: agency }
  let!(:collection) { create :collection }
  # style_guides/form.haml calls .id on the last viewable project.
  let!(:data_source) { create :source_data_source }
  let!(:organization) { create :hud_organization, data_source: data_source }
  let!(:project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
  let(:per_form_tokens) { true }

  around do |example|
    forgery = ActionController::Base.allow_forgery_protection
    per_form = ActionController::Base.per_form_csrf_tokens
    ActionController::Base.allow_forgery_protection = true
    ActionController::Base.per_form_csrf_tokens = per_form_tokens
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = forgery
    ActionController::Base.per_form_csrf_tokens = per_form
  end

  before do
    collection.set_viewables({ data_sources: GrdaWarehouse::DataSource.all.pluck(:id) })
    setup_access_control(user, role, collection)
    sign_in_user(user)
  end

  # jquery_ujs rewrites every hidden token in the live DOM to the global token on
  # DOM ready, so read the server-rendered HTML instead.
  def raw_page_html
    page.evaluate_async_script('fetch(location.href).then(r => r.text()).then(arguments[0])')
  end

  def rendered_token(html, form_selector)
    Nokogiri::HTML(html).at_css("#{form_selector} input[name=authenticity_token]")['value']
  end

  # Rails XORs every rendered token with a fresh one-time pad, so compare the
  # unmasked bytes.
  def unmasked_token(html, form_selector)
    masked = Base64.urlsafe_decode64(rendered_token(html, form_selector))
    pad, encrypted = masked.bytes.each_slice(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH).to_a
    pad.zip(encrypted).map { |a, b| a ^ b }
  end

  describe 'style guide fixture' do
    before { visit form_style_guide_path }

    context 'with per-form tokens enabled' do
      it 'renders a different token for each form action' do
        html = raw_page_html
        expect(unmasked_token(html, '#csrf-form-a')).not_to eq(unmasked_token(html, '#csrf-form-b'))
      end
    end

    context 'with per-form tokens disabled' do
      let(:per_form_tokens) { false }

      it 'renders the same token for each form action' do
        html = raw_page_html
        expect(unmasked_token(html, '#csrf-form-a')).to eq(unmasked_token(html, '#csrf-form-b'))
      end
    end

    it 'submits the filter details form into the ajax modal' do
      click_button 'View universe details'
      within('.modal') do
        expect(page).to have_content('Jan 1, 2024 - Dec 31, 2024')
        expect(page).not_to have_content('InvalidAuthenticityToken')
      end
    end
  end

  describe 'collection Add / Remove modal' do
    let!(:role) { create :admin_role, can_edit_collections: true }
    let!(:target_collection) { create :collection }

    it 'saves the natively submitted modal form' do
      visit admin_collection_path(target_collection)
      find("a[href='#{entities_admin_collection_path(target_collection, entities: :data_sources)}']").click
      within('.modal') do
        check("collection_data_sources_#{data_source.id}", allow_label_click: true)
        click_button 'Save'
      end
      expect(page).to have_content("Collection #{target_collection.name} updated.")
      expect(page).not_to have_content('InvalidAuthenticityToken')
      expect(target_collection.reload.data_sources).to contain_exactly(data_source)
    end
  end

  describe 'LSA Missing Data button' do
    before do
      grant_hud_report(user, 'hud_reports/lsas', role: role)
      visit new_hud_reports_lsa_path
    end

    def click_missing_data
      new_window = window_opened_by { click_button 'Missing Data' }
      switch_to_window(new_window)
    end

    it 'opens the missing data report with the page-load token' do
      click_missing_data
      expect(page).to have_content('Data Issues')
      expect(page).not_to have_content('InvalidAuthenticityToken')
    end

    it 'rejects the token minted for the queue-report action' do
      form_selector = "form[action='#{hud_reports_lsas_path}']"
      token = rendered_token(raw_page_html, form_selector)
      page.execute_script(
        "document.querySelector(\"#{form_selector} input[name=authenticity_token]\").value = arguments[0]",
        token,
      )
      click_missing_data
      expect(page).to have_content('InvalidAuthenticityToken')
    end
  end
end
