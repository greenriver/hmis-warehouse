###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

# Client Veteran Status Form Logic Tests
#
# This test suite validates the complex logic for displaying veteran status
# and military service information fields on client forms. The visibility rules are:
#
# VETERAN STATUS FIELD VISIBILITY:
# - Shown for adult clients (18+ years old)
# - Shown for clients with unknown DOB (age cannot be determined)
# - Hidden for minor clients (under 18) UNLESS they are already marked as Veteran Status = 'Yes'
#   (allows data correction for previously entered incorrect information)
#
# MILITARY SERVICE INFORMATION VISIBILITY:
# - Shown when veteran status is "Yes" AND client form is rendered in "global" context (created/edit client)
# - Shown when veteran status is "Yes" AND client form is rendered in the context of a VA-funded project (creating client in enrollment form)
# - Hidden for all other veteran status responses (No, Client prefers not to answer, etc.)
# - Hidden on client enrollment form for non-VA projects regardless of veteran status
#
# The tests cover both global client creation/editing and enrollment-specific workflows,
# ensuring the form behaves correctly across different contexts and project types.

RSpec.feature 'Client form Veteran Status logic', type: :system do
  let!(:ds1) { create :hmis_primary_data_source, hmis: 'localhost' }
  let!(:hmis_user) { create(:user).related_hmis_user(ds1) }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:p1) { create :hmis_hud_project, data_source: ds1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }

  before(:each) do
    sign_in(hmis_user)
  end

  context 'Creating a new client (global)' do
    before(:each) do
      visit '/client/new'
      expect(page).to have_field('First Name') # ensure form is loaded
    end

    it 'shows veteran status when DOB is unknown' do
      # Don't set DOB - should show veteran status for unknown age
      expect(page).to have_field('Veteran Status')
    end

    it 'shows veteran status initially for adult client' do
      # Set DOB to make client an adult (18+ years old)
      mui_date_select 'Date of Birth', date: 25.years.ago
      expect(page).to have_field('Veteran Status')
    end

    it 'hides veteran status if DOB indicates client is a minor' do
      mui_date_select 'Date of Birth', date: 10.years.ago
      expect(page).not_to have_field('Veteran Status')
    end

    it "shows military service information when veteran status response is 'Yes'" do
      mui_date_select 'Date of Birth', date: 25.years.ago
      mui_select 'Yes', from: 'Veteran Status'
      expect(page).to have_content('Military Service Information')
      expect(page).to have_field('Branch of the Military')
    end

    ['No', 'Client prefers not to answer', 'Data not collected', 'Client doesn\'t know'].each do |response|
      it "hides military service information when veteran status response is '#{response}'" do
        mui_date_select 'Date of Birth', date: 25.years.ago
        mui_select response, from: 'Veteran Status'
        expect(page).not_to have_content('Military Service Information')
      end
    end
  end

  context 'Editing an existing client (global)' do
    before(:each) do
      visit "/client/#{c1.id}/profile/edit"
      expect(page).to have_field('First Name') # ensure form is loaded
    end

    context 'where client is an adult' do
      let(:c1) { create :hmis_hud_client, data_source: ds1, dob: 25.years.ago, veteran_status: 99 }

      it 'shows veteran status field' do
        expect(page).to have_field('Veteran Status')
        expect(page).not_to have_content('Military Service Information')
      end

      it 'shows military service fields when veteran status is Yes' do
        mui_select 'Yes', from: 'Veteran Status'
        expect(page).to have_content('Military Service Information')
        expect(page).to have_field('Branch of the Military')
      end

      it 'allows filling military service information' do
        mui_select 'Yes', from: 'Veteran Status'
        mui_select 'Army', from: 'Branch of the Military'
        fill_in 'Year Entered Military Service', with: '2000'
        fill_in 'Year Separated from Military Service', with: '2008'

        click_button 'Save Changes'
        assert_current_path("/client/#{c1.id}/profile")

        c1.reload
        expect(c1.veteran_status).to eq(1)
        expect(c1.military_branch).to eq(1) # Army
        expect(c1.year_entered_service).to eq(2000)
        expect(c1.year_separated).to eq(2008)
      end
    end

    context 'where client is a minor' do
      let(:c1) { create :hmis_hud_client, data_source: ds1, dob: 15.years.ago, veteran_status: 99 }

      it 'hides veteran status field' do
        expect(page).not_to have_field('Veteran Status')
      end
    end

    context 'where client is a minor with existing Veteran Status = \'Yes\'' do
      let(:c1) { create :hmis_hud_client, data_source: ds1, dob: 15.years.ago, veteran_status: 1 }

      it 'shows veteran status field for data correction' do
        expect(page).to have_field('Veteran Status')
      end

      it 'allows changing veteran status response' do
        mui_select 'No', from: 'Veteran Status'
        expect do
          click_button 'Save Changes'
          assert_current_path("/client/#{c1.id}/profile")
        end.to change { c1.reload.VeteranStatus }.from(1).to(0)
      end

      it 'allows clearing veteran status response' do
        mui_clear_select from: 'Veteran Status'
        expect(page).not_to have_field('Veteran Status') # field gets hidden after clearing
        expect do
          click_button 'Save Changes'
          assert_current_path("/client/#{c1.id}/profile")
          # Note: ClientProcessor processes nil into 99 because veteran status is non-nullable in HUD CSV
        end.to change { c1.reload.VeteranStatus }.from(1).to(99)
      end
    end

    context 'where client is a minor with existing Veteran Status = \'No\'' do
      let(:c1) { create :hmis_hud_client, data_source: ds1, dob: 15.years.ago, veteran_status: 0 }

      it 'shows veteran status field' do
        expect(page).to have_field('Veteran Status')
      end
    end

    context 'where client has unknown DOB' do
      let(:c1) { create :hmis_hud_client, data_source: ds1, dob: nil, veteran_status: nil }

      it 'shows veteran status field' do
        expect(page).to have_field('Veteran Status')
      end
    end
  end

  context 'Creating a new client during Enrollment' do
    before(:each) do
      visit "/projects/#{p1.id}/add-household"
      fill_in 'Search for Client', with: 'xxx'
      click_button 'Search'
      click_button 'Add New Client'
      assert_text 'Enroll a New Client'
      expect(page).to have_field('First Name') # ensure form is loaded
    end

    context 'in non-VA project' do
      it 'does not show military service information, even when veteran status is Yes' do
        expect(page).to have_content('Veteran Status')
        mui_date_select 'Date of Birth', date: 25.years.ago
        mui_select 'Yes', from: 'Veteran Status'
        expect(page).not_to have_content('Military Service Information')
        expect(page).not_to have_content('Branch of Service')
      end
    end

    context 'in VA project' do
      let!(:p1) { create :hmis_hud_project, funders: [20], data_source: ds1 }

      it 'shows military service information when veteran status is Yes' do
        expect(page).to have_content('Veteran Status')
        mui_date_select 'Date of Birth', date: 25.years.ago
        mui_select 'Yes', from: 'Veteran Status'
        expect(page).to have_content('Military Service Information')
        expect(page).to have_field('Branch of the Military')
      end
    end
  end
end
