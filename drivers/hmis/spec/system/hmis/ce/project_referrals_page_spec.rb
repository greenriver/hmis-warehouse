###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'

# Tests what tabs are available on the CE referrals page, depending on a combo of user permissions + project config.
# In the future, coverage could be expanded to test actual referral fields shown.
RSpec.feature 'CE Project Referrals Page', type: :system do
  let!(:ds1) { create :hmis_primary_data_source, hmis: 'localhost' }
  let!(:project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 3, with_coc: true) }

  let!(:admin) { create(:hmis_user, data_source: ds1, first_name: 'Alexandra', last_name: 'Admin') }
  let!(:access_control) { create_access_control(admin, ds1) }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    sign_in(admin)
  end

  def expect_tabs(tabs_names)
    tabs = page.all('[aria-label="Project CE Tabs"] a')
    expect(tabs.map(&:text)).to eq(tabs_names)
  end

  context 'project has no CE config' do
    context 'legacy referrals are enabled via permissions' do
      it 'shows the Referrals page with legacy referrals only' do
        visit "/projects/#{project.id}"
        expect(page).to have_content('Referrals')
        visit "/projects/#{project.id}/referrals"
        expect(page).to have_content('Incoming Referrals')
        expect(page).to have_content('Outgoing Referrals')
        # Tabs are not rendered because only one tab (legacy referrals) is shown
        expect(page).not_to have_selector('[aria-label="Project CE Tabs"]')
      end
    end

    context 'legacy referrals are not enabled via permissions' do
      let!(:access_control) { create_access_control(admin, ds1, without_permission: [:can_manage_incoming_referrals, :can_manage_outgoing_referrals]) }

      it 'does not show the CE referrals page' do
        visit "/projects/#{project.id}"
        expect(page).not_to have_content('Referrals')
        visit "/projects/#{project.id}/referrals"
        expect(page).to have_content('Page not found')
      end
    end
  end

  context 'project receives direct referrals' do
    let!(:project_ce_config) { create(:hmis_project_ce_config, project: project, receives_direct_referrals: true, supports_waitlist_referrals: false) }

    it 'shows the CE referrals page' do
      visit "/projects/#{project.id}/referrals"

      # Since legacy referrals are also shown, 2 tabs are rendered
      expect_tabs(['Referrals', 'Legacy Referrals'])
    end

    context 'user can view their own referrals, not all referrals in the project' do
      let!(:access_control) { create_access_control(admin, ds1, without_permission: [:can_view_referrals]) }

      it 'still shows the CE referrals page' do
        visit "/projects/#{project.id}/referrals"
        expect_tabs(['Referrals', 'Legacy Referrals'])
      end
    end
  end

  context 'project supports waitlist referrals' do
    let!(:project_ce_config) { create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true, receives_direct_referrals: false) }

    it 'shows the CE referrals page' do
      visit "/projects/#{project.id}/referrals"

      expect_tabs(['Referrals', 'Available Units', 'Legacy Referrals'])
    end

    context 'but user does not have permission to view units' do
      let!(:access_control) { create_access_control(admin, ds1, without_permission: [:can_view_units]) }

      it 'shows the CE referrals page with legacy referrals only' do
        visit "/projects/#{project.id}/referrals"

        expect_tabs(['Referrals', 'Legacy Referrals'])
      end
    end
  end

  context 'project sends direct referrals' do
    let!(:project_ce_config) { create(:hmis_project_sends_direct_ce_referrals_config, project: project) }

    it 'shows the CE referrals page and allows sending direct referrals' do
      visit "/projects/#{project.id}/referrals"

      expect_tabs(['Outgoing Referrals', 'Legacy Referrals'])
      expect(page).to have_link('Send Referral')
      click_link 'Send Referral'
      expect(page).to have_content('HoH Enrollment (Required)')
      expect(page).to have_content('Project (Required)')
    end

    context 'user can manage outgoing referrals, but not view referrals in the target project' do
      let!(:access_control) { create_access_control(admin, ds1, without_permission: [:can_view_referrals]) }

      it 'shows the CE referrals page and allows sending direct referrals' do
        visit "/projects/#{project.id}/referrals"

        expect_tabs(['Outgoing Referrals', 'Legacy Referrals'])
        expect(page).to have_link('Send Referral')
      end
    end

    context 'user can view but not manage outgoing referrals' do
      let!(:access_control) { create_access_control(admin, ds1, without_permission: [:can_manage_outgoing_referrals]) }

      it 'shows the CE referrals page but does not allow sending direct referrals' do
        visit "/projects/#{project.id}/referrals"

        expect_tabs(['Outgoing Referrals', 'Legacy Referrals'])
        expect(page).not_to have_link('Send Referral')
      end
    end

    context 'user cannot view or manage outgoing referrals' do
      let!(:access_control) { create_access_control(admin, ds1, without_permission: [:can_manage_outgoing_referrals, :can_view_outgoing_referral_details, :can_manage_incoming_referrals]) }
      let!(:project_ce_config) { create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true) } # Project also accepts referrals

      it 'does not show the Outgoing Referrals tab' do
        visit "/projects/#{project.id}/referrals"

        expect_tabs(['Referrals', 'Available Units'])
        expect(page).not_to have_content('Outgoing Referrals')
        expect(page).not_to have_link('Send Referral')
      end
    end
  end
end
