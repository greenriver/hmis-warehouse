###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Enrollment/view only access', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Quentin', last_name: 'Coldwater' }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, first_name: 'Alice', last_name: 'Quinn' }

  before(:each) do
    sign_in(hmis_user)
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_clients, :can_view_client_name, :can_view_project, :can_view_enrollment_details]) }
  let!(:today) { Date.current }

  # Forms created in base setup
  let(:intake_form) { Hmis::Form::Definition.find_by(role: :INTAKE) }
  let(:exit_form) { Hmis::Form::Definition.find_by(role: :EXIT) }

  describe 'Enrollment Overview' do
    context 'when enrollment is wip' do
      let!(:e1) { create :hmis_hud_wip_enrollment, client: c1, data_source: ds1, project: p1 }
      let!(:e2) { create :hmis_hud_wip_enrollment, client: c2, data_source: ds1, project: p1, household_id: e1.household_id }

      it 'shows enrollment details, but links and actions are not available' do
        visit "/client/#{c1.id}/enrollments/#{e1.id}"

        expect(page).to have_text 'Incomplete'
        expect(page).not_to have_link 'Go to Intake Assessment'
        expect(page).not_to have_link 'Go to Exit Assessment'
        expect(page).not_to have_button 'Delete Enrollment'

        # Household tasks are visible, but not clickable
        expect(page).to have_text 'Finish Intake Assessment'
        expect(page).not_to have_link 'Finish Intake Assessment'
      end

      context "when one household member's intake has been started" do
        let!(:intake) { create(:hmis_wip_custom_assessment, data_collection_stage: 1, enrollment: e1, data_source: ds1, definition: intake_form, values: { entry_date: today - 2.days }) }

        it 'shows assessment details, but cannot be edited or submitted' do
          visit "/client/#{c1.id}/enrollments/#{e1.id}"
          # Overview still does not show intake link, since it hasn't been submitted
          expect(page).not_to have_link 'Go to Intake Assessment'

          # However, user can navigate directly to the intake and view the saved (unsubmitted) values
          visit "/client/#{c1.id}/enrollments/#{e1.id}/intake"
          expect(page).to have_text 'Quentin Coldwater'
          expect(page).to have_text 'This assessment is in progress.'
          expect(page).to have_text "Entry Date #{(today - 2.days).strftime('%m/%d/%Y')}"

          # User cannot navigate to the other household member, whose intake hasn't been started yet
          expect(page).not_to have_text 'Alice Quinn'
          # User cannot navigate to the summary tab
          expect(page).not_to have_text 'Complete Intake'

          # Form is locked and user can't edit fields or submit
          expect(page).not_to have_button 'Unlock'
          # No inputs in the main container page. (Searching inside the MuiContainer instead of the whole page, since the search box still appears in the top bar)
          expect(find('.MuiContainer-root')).not_to have_css('input')
          expect(page).not_to have_button 'Submit'
          # The only actionable thing the user can do is print
          expect(page).to have_link 'Print'
        end
      end
    end

    context 'when enrollment is complete' do
      let!(:e1) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p1, entry_date: today - 2.days }
      let!(:e2) { create :hmis_hud_enrollment, client: c2, data_source: ds1, project: p1, household_id: e1.household_id, entry_date: today - 2.days }
      let!(:intake1) { create(:hmis_custom_assessment, data_collection_stage: 1, enrollment: e1, data_source: ds1, definition: intake_form) }
      let!(:intake2) { create(:hmis_custom_assessment, data_collection_stage: 1, enrollment: e2, data_source: ds1, definition: intake_form) }

      it 'shows enrollment details, including Go to Intake button' do
        visit "/client/#{c1.id}/enrollments/#{e1.id}"

        expect(page).to have_text 'All tasks complete'
        expect(page).to have_link 'Go to Intake Assessment'
        expect(page).not_to have_link 'Go to Exit Assessment'

        click_link 'Go to Intake Assessment'
        expect(page).to have_text 'Quentin Coldwater'
        expect(page).to have_text 'This assessment has been submitted.'
        expect(page).to have_text "Entry Date #{(today - 2.days).strftime('%m/%d/%Y')}"

        click_button 'Alice Quinn'
        expect(page).to have_text 'This assessment has been submitted.'
        expect(page).to have_text "Entry Date #{(today - 2.days).strftime('%m/%d/%Y')}"

        # User cannot navigate to the summary tab or attempt to unlock
        expect(page).not_to have_text 'Complete Intake'
        expect(page).not_to have_button 'Unlock'
      end
    end

    context 'when enrollment is exited' do
      let!(:e1) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p1, entry_date: today - 2.years, exit_date: today }
      let!(:e2) { create :hmis_hud_enrollment, client: c2, data_source: ds1, project: p1, household_id: e1.household_id, entry_date: today - 1.year, exit_date: today }
      let!(:intake1) { create(:hmis_custom_assessment, data_collection_stage: 1, enrollment: e1, data_source: ds1, definition: intake_form) }
      let!(:intake2) { create(:hmis_custom_assessment, data_collection_stage: 1, enrollment: e2, data_source: ds1, definition: intake_form) }
      let!(:exit1) { create(:hmis_custom_assessment, data_collection_stage: 3, enrollment: e1, data_source: ds1, definition: exit_form) }
      let!(:exit2) { create(:hmis_custom_assessment, data_collection_stage: 3, enrollment: e2, data_source: ds1, definition: exit_form) }

      it 'shows enrollment details, including Go to Exit button' do
        visit "/client/#{c1.id}/enrollments/#{e1.id}"

        expect(page).to have_link 'Go to Intake Assessment'
        expect(page).to have_link 'Go to Exit Assessment'
        click_link 'Go to Exit Assessment'
        expect(page).to have_text 'Quentin Coldwater'
        expect(page).to have_text 'This assessment has been submitted.'
        expect(page).to have_text "Exit Date #{today.strftime('%m/%d/%Y')}"
        expect(page).not_to have_text 'Complete Intake'
        expect(page).not_to have_button 'Unlock'
      end
    end
  end
end
