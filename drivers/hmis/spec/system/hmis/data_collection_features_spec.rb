###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Data collection features', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 4 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:hoh) { create :hmis_hud_client, first_name: 'Annie', data_source: ds1 }
  let!(:spouse) { create :hmis_hud_client, first_name: 'Jessie', data_source: ds1 }
  let!(:hoh_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: hoh, entry_date: 1.month.ago, household_id: 'household1', relationship_to_hoh: 1 }
  let!(:spouse_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: spouse, entry_date: 1.month.ago, household_id: 'household1', relationship_to_hoh: 3 }
  let(:today) { Date.current }

  before(:each) do
    sign_in(hmis_user)
  end

  def side_nav_elements
    find_all('a[id^="side-nav-"]').map(&:text)
  end

  context 'when no CLS is enabled in the project' do
    it 'should not show CLS in the project side nav' do
      visit "/projects/#{p1.id}/overview"
      expect(side_nav_elements).not_to include('Current Living Situations')
    end

    it 'should not show CLS in the enrollment side nav' do
      visit "/client/#{hoh.id}/enrollments/#{hoh_enrollment.id}/overview"
      expect(side_nav_elements).not_to include('Current Living Situations')

      visit "/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/overview"
      expect(side_nav_elements).not_to include('Current Living Situations')
    end

    context 'but legacy migrated-in CLS data exists' do
      let!(:cls) { create(:hmis_current_living_situation, client: spouse, enrollment: spouse_enrollment, current_living_situation: 118, location_details: 'A comment') }

      it 'should show CLS in the project nav' do
        visit "/projects/#{p1.id}/overview"
        expect(side_nav_elements).to include('Current Living Situations')

        click_link 'Current Living Situations'
        table_row = find('tbody').find_all('tr').sole.text
        expect(table_row).to include(spouse.first_name)
        expect(table_row).to include('Safe Haven')

        click_link spouse.first_name
        assert_current_path("/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/current-living-situations")
      end

      it 'should not show CLS in the nav for the enrollment without data' do
        visit "/client/#{hoh.id}/enrollments/#{hoh_enrollment.id}/overview"
        expect(side_nav_elements).not_to include('Current Living Situations')
      end

      it 'should allow viewing legacy CLS but not creating new' do
        visit "/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/overview"
        expect(side_nav_elements).to include('Current Living Situations')

        click_link 'Current Living Situations'

        table_row = find('tbody').find_all('tr').sole.text
        expect(table_row).to include('Safe Haven')
        expect(table_row).to include('A comment')

        assert_no_text 'Add Current Living Situation'

        find('tbody').first('tr').trigger(:click)
        assert_text 'View Current Living Situation'
        assert_no_text 'Not Found'
        assert_text 'Current Living Situation Safe Haven'
        assert_text 'Location details A comment'
      end
    end

    # TODO(#6113) - Uncomment and update this system test when correct behavior is implemented
    # context 'legacy CLS data exists with a form processor' do
    #   # it references a definition that's different from the project default
    #   let!(:definition_json) do # simplified CLS definition
    #     {
    #       'item': [
    #         {
    #           'text': 'What date? This item is customized',
    #           'type': 'DATE',
    #           'link_id': 'date',
    #           'mapping': {
    #             'field_name': 'informationDate',
    #           },
    #         },
    #         {
    #           'text': 'Current Living Situation',
    #           'type': 'CHOICE',
    #           'link_id': 'cls',
    #           'mapping': {
    #             'field_name': 'currentLivingSituation',
    #           },
    #           'pick_list_reference': 'CURRENT_LIVING_SITUATION',
    #         },
    #       ],
    #     }
    #   end
    #   let!(:definition) { create :hmis_form_definition, title: 'Custom CLS', role: 'CURRENT_LIVING_SITUATION', data_source: ds1, definition: definition_json, identifier: 'custom_cls' }
    #   let!(:cls) { create(:hmis_current_living_situation, client: spouse, enrollment: spouse_enrollment, current_living_situation: 118) }
    #   let!(:proc) { create(:hmis_form_processor, definition: definition, owner: cls) }
    #
    #   it 'allows viewing the legacy CLS with the non-default form' do
    #     visit "/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/current-living-situations"
    #
    #     table_row = find('tbody').find_all('tr').sole.text
    #     expect(table_row).to include('Safe Haven')
    #     assert_no_text 'Add Current Living Situation'
    #
    #     find('tbody').first('tr').trigger(:click)
    #     assert_text 'View Current Living Situation'
    #     assert_text 'What date? This item is customized'
    #   end
    # end
  end

  context 'when no case note is enabled in the project, but legacy data exists' do
    # This is a similar test using Case Notes, which allow editing existing records (which CLS doesn't).
    # It's worth keeping the CLS tests too, since Case Notes are only available on the Enrollment dash,
    # unlike CLS which is available on both project and enrollment
    let!(:case_note) do
      create(:hmis_hud_custom_case_note, data_source: ds1, client: hoh, enrollment: hoh_enrollment, user: u1, content: 'A legacy custom case note')
    end

    it 'should allow viewing and editing legacy Case Note, but not creating new' do
      visit "/client/#{hoh.id}/enrollments/#{hoh_enrollment.id}/overview"
      expect(side_nav_elements).to include('Case Notes')

      click_link 'Case Notes'

      table_row = find('tbody').find_all('tr').sole.text
      expect(table_row).to include('A legacy custom case note')

      assert_no_text 'Add Case Note'

      find('tbody').first('tr').trigger(:click)
      click_button 'Edit'
      fill_in 'Note', with: 'An updated legacy custom case note'
      click_button 'Save'
      assert_text 'Displaying 1 of 1 case note'
      assert_no_text 'Edit Case Note'
      case_note.reload
      expect(case_note.content).to eq('An updated legacy custom case note')
    end
  end

  context 'when CLS is enabled in the project for HoH only' do
    let!(:instance) { create :hmis_form_instance, role: 'CURRENT_LIVING_SITUATION', entity: p1, definition_identifier: 'current_living_situation', data_collected_about: 'HOH' }

    it 'should show CLS in project nav' do
      visit "/projects/#{p1.id}/overview"
      expect(side_nav_elements).to include('Current Living Situations')
    end

    it 'should not show CLS in the nav for the non-HoH enrollment' do
      visit "/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/overview"
      expect(side_nav_elements).not_to include('Current Living Situations')
      visit "/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/current-living-situations"
      assert_text 'Page not found.'
    end

    it 'should show CLS in HoH enrollment nav and allow editing' do
      visit "/client/#{hoh.id}/enrollments/#{hoh_enrollment.id}/overview"
      expect(side_nav_elements).to include('Current Living Situations')

      click_link 'Current Living Situations'
      assert_text 'No current living situations'

      click_button 'Add Current Living Situation'
      mui_date_select 'Information Date', date: today
      mui_select 'Long-term care facility or nursing home', from: 'Current Living Situation'
      fill_in 'Location details', with: 'Here are some details'
      click_button 'Save'
      assert_text('Long-term care facility or nursing home')
    end

    context 'when legacy data exists for someone who is no longer HoH' do
      let!(:cls) { create(:hmis_current_living_situation, client: spouse, enrollment: spouse_enrollment, current_living_situation: 118, location_details: 'Legacy!') }

      it 'still allows you to see legacy data, but not create new' do
        visit "/client/#{spouse.id}/enrollments/#{spouse_enrollment.id}/overview"
        expect(side_nav_elements).to include('Current Living Situations')
        click_link 'Current Living Situations'
        table_row = find('tbody').find_all('tr').sole.text
        expect(table_row).to include('Safe Haven')
        expect(table_row).to include('Legacy!')
        assert_no_text 'Add Current Living Situation'
      end
    end
  end
end
