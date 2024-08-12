require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Assessment definition selection', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 4 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Han', last_name: 'Solo' }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 1.month.ago }

  let(:today) { Date.current }

  # Individual Custom Assessment
  #   Starting a new one
  #      Filters form by Project context
  #      Filters form by Client Attributes (Data Collected About)

  #   Where the Assessment was submitted using a previous version
  #   Opened for Viewing
  #      Uses the original version
  #      Filters form by Project context
  #      Filters form by Client Attributes (Data Collected About)
  #   Opened for Editing
  #      Uses the newer published version
  #      Filters form by Project context
  #      Filters form by Client Attributes (Data Collected About)
  #
  # Household: Intake
  # Household: Exit
  # Locations to test assessment forms:
  # - Individual (existing)
  # - Individual (new)
  # - Household (new)
  # - Household (some existing of previous versions)
  context 'For Custom Assessment with rules for project type and data_collected_about' do
    let!(:definition) { create :custom_assessment_with_custom_fields_and_rules, title: 'Very Custom Assessment', data_source: ds1 }

    before(:each) do
      create(:hmis_form_instance, definition: definition, entity: p1) # enable the form in p1
      sign_in(hmis_user)
      disable_transitions

      visit "/client/#{c1.id}/enrollments/#{e1.id}/assessments"
    end

    def submit_assessment
      click_button 'Submit'
      assert_text "#{c1.brief_name} Assessments" # wait until we're back on the assessment table
    end

    context 'creating a new assessment' do
      context 'non-Veteran non-ES Enrollment' do
        it 'hides both conditional items' do
          click_button 'New Assessment'
          click_link definition.title

          mui_date_select 'Assessment Date', date: today
          assert_no_text 'Custom field for ES projects only'
          assert_no_text 'Custom field for Veteran HoH only'

          expect do
            submit_assessment
          end.to change(e1.custom_assessments, :count).by(1).
            and change(e1.custom_assessments.not_in_progress.
              with_form_definition_identifier(definition.identifier).
              where(assessment_date: today), :count).by(1).
            and change(Hmis::Hud::CustomDataElement, :count).by(0)
        end
      end
      context 'Veteran ES Enrollment' do
        before(:each) do
          p1.update!(ProjectType: 1)
          c1.update!(VeteranStatus: 1)
        end
        it 'shows both conditional items' do
          click_button 'New Assessment'
          click_link definition.title

          mui_date_select 'Assessment Date', date: today
          fill_in 'Custom field for ES projects only', with: 'value 1'
          fill_in 'Custom field for Veteran HoH only', with: 'value 2'

          expect do
            submit_assessment
          end.to change(e1.custom_assessments, :count).by(1).
            and change(e1.custom_assessments.not_in_progress.
              with_form_definition_identifier(definition.identifier).
              where(assessment_date: today), :count).by(1).
            and change(Hmis::Hud::CustomDataElement, :count).by(2)
        end
      end
    end
    context 'opening an existing assessment' do
      let!(:assessment) { create(:hmis_custom_assessment, definition: definition, enrollment: e1, client: c1, assessment_date: today) }

      context 'non-Veteran non-ES Enrollment' do
        it 'hides both conditional items' do
          click_link definition.title
          assert_text 'Assessment Date'
          assert_no_text 'Custom field for ES projects only'
          assert_no_text 'Custom field for Veteran HoH only'
          assert_text 'Unlock Assessment'
        end
      end
      context 'Veteran ES Enrollment' do
        before(:each) do
          p1.update!(ProjectType: 1)
          c1.update!(VeteranStatus: 1)
        end

        it 'shows both conditional items' do
          click_link definition.title
          assert_text 'Assessment Date'
          assert_text 'Custom field for ES projects only'
          assert_text 'Custom field for Veteran HoH only'
          assert_text 'Unlock Assessment'
        end
      end
    end

    context 'opening an existing assessment that was submitted using an old version of the form' do
      let!(:old_definition) do
        fd = create(:custom_assessment_with_custom_fields_and_rules, identifier: definition.identifier, title: 'Previous Very Custom Assessment', data_source: ds1, version: 0, status: :retired)
        fd.definition['item'][0]['item'] << { 'type': 'DISPLAY', 'link_id': 'old_message', 'text': 'Text on old form' }
        fd.save!
        fd
      end
      let!(:assessment) { create(:hmis_custom_assessment, definition: old_definition, enrollment: e1, client: c1, assessment_date: today) }

      # TODO gig split this into two files
      # 1) testing rules and data_collected_about application, both in individual and household
      # 2) testing opening legacy forms, both in individual and household
      context 'non-Veteran non-ES Enrollment' do
        it 'hides both conditional items' do
          click_link old_definition.title

          assert_text old_definition.title
          assert_text 'Assessment Date'
          assert_no_text 'Custom field for ES projects only'
          assert_no_text 'Custom field for Veteran HoH only'
          assert_text 'Text on old form'

          click_button('Unlock Assessment', match: :first) # unlocking the assessment should upgrade to the newer form
          assert_no_text old_definition.title
          assert_text definition.title
          assert_text 'Assessment Date'
          assert_no_text 'Custom field for ES projects only'
          assert_no_text 'Custom field for Veteran HoH only'
          assert_no_text 'Text on old form'
        end
      end
      context 'Veteran ES Enrollment' do
        before(:each) do
          p1.update!(ProjectType: 1)
          c1.update!(VeteranStatus: 1)
        end

        it 'shows both conditional items' do
          click_link definition.title
          assert_text 'Unlock Assessment'
          assert_text 'Assessment Date'
          assert_text 'Custom field for ES projects only'
          assert_text 'Custom field for Veteran HoH only'
          assert_text 'Text on old form'

          click_button('Unlock Assessment', match: :first) # unlocking the assessment should upgrade to the newer form
          assert_no_text old_definition.title
          assert_text definition.title
          assert_text 'Assessment Date'
          assert_no_text 'Custom field for ES projects only'
          assert_no_text 'Custom field for Veteran HoH only'
          assert_no_text 'Text on old form'
        end
      end
    end
  end
end
