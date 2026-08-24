###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'

## System spec for restricted clients.
# Covers search omission, permitted vs redacted profile PII, and restrict/unrestrict from the profile button.
# Permission and GraphQL behavior are tested in more detail in restricted_client_redaction_spec,
# set_client_restricted_spec, client_access_spec, and hmis_client_policy_spec.
RSpec.feature 'Restricted clients', type: :system do
  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: 'localhost') }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }

  let!(:p1) { create :hmis_hud_project, data_source: ds1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1 }

  # Data-source access covers every project in ds1 (including p2), which is what lets the user
  # open a client enrolled only at p2. Restricted-client permission is only at p1.
  let(:pii_permissions) { [:can_view_clients, :can_view_client_name, :can_view_dob, :can_view_full_ssn] }
  let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: pii_permissions) }
  let!(:p1_access_control) do
    create_access_control(
      hmis_user,
      p1,
      with_permission: pii_permissions + [:can_view_restricted_clients, :can_view_enrollment_details],
    )
  end

  let(:shared_last_name) { 'Rcspec' }
  let(:dob) { 24.years.ago.to_date }
  let(:ssn) { '123-45-6789' }

  let!(:normal_client) do
    create :hmis_hud_client, data_source: ds1, first_name: 'Willow', last_name: shared_last_name, dob: dob, ssn: ssn, with_enrollment_at: p1
  end
  let!(:restricted_at_p1) do
    create(:hmis_hud_client, data_source: ds1, first_name: 'Hazel', last_name: shared_last_name, dob: dob, ssn: ssn, with_enrollment_at: p1).tap do |client|
      client.mark_as_restricted!(user: hmis_user)
    end
  end
  let!(:restricted_elsewhere) do
    create(:hmis_hud_client, data_source: ds1, first_name: 'Ivy', last_name: shared_last_name, dob: dob, ssn: ssn, with_enrollment_at: p2).tap do |client|
      client.mark_as_restricted!(user: hmis_user)
    end
  end

  let(:no_results_text) { /no data|no results found/i }

  before(:each) do
    sign_in(hmis_user)
    visit '/'
  end

  def search_clients_for(term)
    visit '/'
    fill_in 'search clients', with: term.to_s
    find_field('search clients').send_keys(:enter)
    expect(page).not_to have_css('[data-testid="loading"]') # wait for Loading component to disappear
  end

  def omnisearch_for(term)
    visit '/'
    fill_in 'Client and Project search', with: term.to_s
    expect(page).not_to have_css('[data-testid="loading"]') # wait for Loading component to disappear
  end

  def expect_no_search_results_for(client)
    expect(page).not_to have_text("#{client.first_name} #{client.last_name}")
    expect(page).not_to have_text(client.masked_name)
  end

  describe 'search' do
    it 'returns unrestricted and permitted restricted clients, but not restricted clients enrolled only elsewhere' do
      search_clients_for(shared_last_name)

      expect(page).to have_text('Displaying 2 of 2 clients')
      table = find('table')
      expect(table).to have_text("#{normal_client.first_name} #{normal_client.last_name}")
      expect(table).to have_text("#{restricted_at_p1.first_name} #{restricted_at_p1.last_name}")
      expect_no_search_results_for(restricted_elsewhere)
    end

    it 'does not return restricted_elsewhere when looking up by ID or PersonalID' do
      search_clients_for(restricted_elsewhere.personal_id)
      expect(page).to have_text(no_results_text)
      expect_no_search_results_for(restricted_elsewhere)

      search_clients_for(restricted_elsewhere.id)
      expect(page).to have_text(no_results_text)
      expect_no_search_results_for(restricted_elsewhere)
    end
  end

  describe 'omnisearch' do
    it 'offers unrestricted and permitted restricted clients, but not restricted clients enrolled only elsewhere' do
      omnisearch_for(shared_last_name)

      expect(page).to have_text("#{normal_client.first_name} #{normal_client.last_name}")
      expect(page).to have_text("#{restricted_at_p1.first_name} #{restricted_at_p1.last_name}")
      expect_no_search_results_for(restricted_elsewhere)
    end

    it 'does not offer restricted_elsewhere when looking up by ID or PersonalID' do
      omnisearch_for(restricted_elsewhere.personal_id)
      expect(page).to have_text(no_results_text)
      expect_no_search_results_for(restricted_elsewhere)

      omnisearch_for(restricted_elsewhere.id)
      expect(page).to have_text(no_results_text)
      expect_no_search_results_for(restricted_elsewhere)
    end
  end

  describe 'client profile' do
    it 'shows real PII and a Restricted Record chip when the user can view the restricted client' do
      visit "/client/#{restricted_at_p1.id}/profile"

      expect(page).to have_text("#{restricted_at_p1.first_name} #{restricted_at_p1.last_name}")
      # find all elements hidden with data-testid="clickToShow", and click them to expose pii on the page
      all('[data-testid="clickToShow"]').each(&:click)

      expect(page).to have_text(restricted_at_p1.dob.strftime('%m/%d/%Y'))
      expect(page).to have_text(restricted_at_p1.ssn)

      expect(page).to have_text('Restricted Record')
      expect(page).not_to have_button('Restrict Client Record')
      expect(page).not_to have_button('Remove Client Record Restriction')
    end

    it 'loads with masked PII and still shows the Restricted Record chip explaining the redaction' do
      visit "/client/#{restricted_elsewhere.id}/profile"

      expect(page).to have_text(restricted_elsewhere.masked_name)
      expect(page).not_to have_text(restricted_elsewhere.first_name)
      expect(page).to have_text('Age') # age is still shown
      expect(page).not_to have_text('DOB')
      expect(page).not_to have_text('SSN')
      expect(page).not_to have_css('[data-testid="clickToShow"]') # no hidden PII to expose
      expect(page).to have_text('Restricted Record')
    end

    it 'does not show a Restricted Record chip or restrict button on an unrestricted client when the user cannot mark records as restricted' do
      visit "/client/#{normal_client.id}/profile"

      expect(page).to have_text("#{normal_client.first_name} #{normal_client.last_name}")
      expect(page).not_to have_text('Restricted Record')
      expect(page).not_to have_button('Restrict Client Record')
    end
  end

  context 'when the user can mark clients as restricted' do
    before do
      add_permissions(p1_access_control, :can_mark_clients_as_restricted)
    end

    it 'restricts an unrestricted client from the profile button' do
      visit "/client/#{normal_client.id}/profile"

      expect(page).to have_text('Restrict Client Record') # ensure loaded
      expect(page).not_to have_text('Restricted Record') # chip not present
      click_button 'Restrict Client Record'
      expect(page).to have_css('[role="dialog"]', text: 'Restrict Client Record')
      within('[role="dialog"]') { click_button 'Restrict' }

      expect(page).to have_text('Restricted Record') # chip present
      expect(page).to have_button('Remove Client Record Restriction')
      expect(normal_client.reload.restricted?).to be true
      expect(Hmis::RestrictedRecord.for_clients.find_by(restrictable: normal_client)).to be_present
    end

    it 'removes restriction from a restricted client from the profile button' do
      visit "/client/#{restricted_at_p1.id}/profile"

      expect(page).to have_text('Restricted Record')
      click_button 'Remove Client Record Restriction'
      expect(page).to have_css('[role="dialog"]', text: 'Remove Client Record Restriction')
      within('[role="dialog"]') { click_button 'Remove Restriction' }

      expect(page).not_to have_text('Restricted Record')
      expect(page).to have_button('Restrict Client Record')
      expect(restricted_at_p1.reload.restricted?).to be false
    end
  end
end
