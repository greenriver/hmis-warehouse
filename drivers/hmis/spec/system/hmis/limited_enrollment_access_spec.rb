###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Enrollment/household management', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:p1) { create :hmis_hud_project, project_name: 'Full Access Project', data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, project_name: 'Limited Access Project', data_source: ds1, organization: o1 }

  let!(:client) { create :hmis_hud_client, data_source: ds1, first_name: 'Quentin', last_name: 'Coldwater' }
  let!(:e1_full_access) { create :hmis_hud_enrollment, client: client, data_source: ds1, project: p1 }
  let!(:e2_limited_access) { create :hmis_hud_enrollment, client: client, data_source: ds1, project: p2, move_in_date: 1.week.ago }
  let!(:e1_staff_assignment) { create :hmis_staff_assignment, data_source: ds1, enrollment: e1_full_access }

  # cruft: enrollment at another project that user does not have permission to see
  let!(:p3) { create :hmis_hud_project, project_name: 'Hidden Project', data_source: ds1, organization: o1 }
  let!(:e3) { create :hmis_hud_enrollment, client: client, data_source: ds1, project: p3 }

  before(:each) do
    sign_in(hmis_user)
  end

  context 'A user who has full access to p1 and limited access to p2' do
    # full enrollment visibility for p1
    let!(:access_control1) { create_access_control(hmis_user, p1, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details]) }
    # limited enrollment visibility for p2
    let!(:access_control2) { create_access_control(hmis_user, p2, with_permission: [:can_view_limited_enrollment_details]) }

    # user should see both full-access and limited-access enrollments
    it 'sees both enrollments on client dashboard' do
      visit "/client/#{client.id}/enrollments"
      assert_text 'Displaying 2 of 2 enrollments'
      # enrollment at p1 is linked
      assert_text p1.project_name
      expect(page).to have_link(p1.project_name)
      # enrollment at p2 is not linked
      assert_text p2.project_name
      expect(page).not_to have_link(p2.project_name)
    end

    it 'can expand optional columns (regression #7563)' do
      visit "/client/#{client.id}/enrollments"
      click_button 'Columns'

      # dynamically select all optional columns
      all('.MuiPopover-root label').each do |label|
        mui_click_checkbox(label.text)
      end
      click_button 'Apply'

      # ensure assigned staff is now visible on the table
      assert_text e1_staff_assignment.user.full_name
      assert_text 'Assigned Staff'
    end

    it 'cannot load enrollment dashboard for limited access enrollment' do
      visit "/client/#{client.id}/enrollments/#{e2_limited_access.id}"
      assert_text 'Page not found'
    end
  end

  context 'A user who can not view any enrollments' do
    # give user access to view the client record
    let!(:access_control1) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients]) }

    it 'sees no enrollments on client dashboard' do
      visit "/client/#{client.id}"
      # Enrollment tab doesn't appear at all, because the user does not have can_view_enrollment_details for any of this client's enrollments
      expect(page).not_to have_link('Enrollments')
    end

    it 'cannot load enrollment dashboard' do
      visit "/client/#{client.id}/enrollments/#{e1_full_access.id}"
      assert_text 'Page not found'
    end
  end
end
