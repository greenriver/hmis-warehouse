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

  # Test context for viewing/editing an "individual assessment" (non-household) using a Custom Assessment form
  context 'Performing individual Custom Assessment' do
    let!(:old_definition) do
      old_item = {
        'type': 'DISPLAY',
        'link_id': 'old_message',
        'text': 'Text on old form',
      }
      create(:custom_assessment_with_custom_fields, title: 'Old Custom Assessment', append_items: old_item, data_source: ds1, version: 0, status: :retired)
    end

    let!(:definition) do
      new_item = {
        'type': 'STRING',
        'link_id': 'new_question',
        'text': 'New question',
        'mapping': { 'custom_field_key': 'new_question_key' },
      }
      create(:custom_assessment_with_custom_fields, identifier: old_definition.identifier, title: 'New Custom Assessment', append_items: new_item, data_source: ds1)
    end

    before(:each) do
      create(:hmis_form_instance, definition: definition, entity: p1) # enable the form in p1
      sign_in(hmis_user)

      visit "/client/#{c1.id}/enrollments/#{e1.id}/assessments"
    end

    context 'with no existing assessment' do
      it 'creates a new assessment with the most recent form version' do
        click_button 'New Assessment'
        click_link definition.title
        mui_date_select 'Assessment Date', date: today

        expect do
          click_button 'Submit'
          assert_text "#{c1.brief_name} Assessments" # wait until we're back on the assessment table
        end.to change(e1.custom_assessments, :count).by(1).
          and change(definition.form_processors, :count).by(1)

        expect(e1.custom_assessments.first.form_processor.definition_id).to eq(definition.id)
      end
    end

    context 'with an existing assessment that was created with an old definition' do
      let!(:assessment) { create(:hmis_custom_assessment, definition: old_definition, enrollment: e1, assessment_date: today) }

      it 'opens the assessment with the original form version' do
        click_link old_definition.title

        assert_text old_definition.title
        assert_text 'Assessment Date'
        assert_text assessment.assessment_date.strftime('%m/%d/%Y')
        assert_text 'Text on old form'
      end

      it 'upgrades to the newer version when you unlock for editing' do
        click_link old_definition.title

        assert_text old_definition.title

        # unlock the assessment should upgrade to the newer form
        click_button('Unlock Assessment', match: :first)
        assert_text 'Submit' # Unlock succeeded
        assert_no_text old_definition.title
        assert_text definition.title
        expect(page).to have_field('Assessment Date', with: assessment.assessment_date.strftime('%m/%d/%Y'))
        assert_no_text 'Text on old form'

        # fill in the new question and submit, to ensure it is saved
        fill_in 'new_question', with: 'Answer to new question'
        expect do
          click_button 'Submit'
          assert_text "#{c1.brief_name} Assessments"
        end.to change(e1.custom_assessments, :count).by(0).
          and change(assessment.custom_data_elements, :count).by(1)

        expect(assessment.reload.form_processor.definition_id).to eq(definition.id)
        expect(assessment.custom_data_elements.where(value_string: 'Answer to new question')).to exist

        # Re-open the assessment to ensure it is using the new form now
        assert_no_text old_definition.title
        click_link definition.title
        assert_text 'New question'
        assert_text 'Answer to new question'
        assert_no_text 'Text on old form'
        assert_text 'Unlock Assessment'
      end
    end

    context 'with an existing WIP assessment that was created with an old definition' do
      let!(:wip_assessment) { create(:hmis_custom_assessment, definition: old_definition, wip: true, values: { 'assessment_date': today.strftime('%Y-%m-%d') }, enrollment: e1, assessment_date: today) }

      it 'uses old form version for editing' do
        click_link old_definition.title
        assert_text old_definition.title
        expect(page).to have_field('Assessment Date', with: wip_assessment.assessment_date.strftime('%m/%d/%Y'))
        assert_text 'Text on old form'

        # Submit should use old form definition
        click_button 'Submit'
        assert_text "#{c1.brief_name} Assessments"

        expect(wip_assessment.reload.wip).to eq(false)
        expect(wip_assessment.reload.form_processor.definition_id).to eq(old_definition.id)
      end
    end
  end

  # Test context for viewing/editing a "household assessment" using an Intake form
  # Household contains 4 members each with differently configured assessments, to ensure
  # that the correct form version is used for each member, even in the Household Assessments view.
  context 'Performing Household Intake assessments with various definition versions' do
    let!(:old_definition) do
      old_item = {
        'type': 'STRING',
        'link_id': 'old_question',
        'text': 'Old question',
        'mapping': { 'custom_field_key': 'old_question_key' },
      }
      create(:hmis_intake_assessment_definition, title: 'Old Special Intake', append_items: old_item, data_source: ds1, version: 0, status: :retired)
    end

    let!(:definition) do
      new_item = {
        'type': 'STRING',
        'link_id': 'new_question',
        'text': 'New question',
        'mapping': { 'custom_field_key': 'new_question_key' },
      }
      create(:hmis_intake_assessment_definition, identifier: old_definition.identifier, title: 'New Special Intake', append_items: new_item, data_source: ds1)
    end

    # e1 (HoH): Intake was Submitted with old form
    let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Parent', last_name: 'Jones' }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 25.days.ago, relationship_to_hoh: 1 }
    let!(:e1_assessment) { create(:hmis_intake_assessment, definition: old_definition, enrollment: e1) }

    # e2 (spouse): Intake was Submitted with published form
    let!(:c2) { create :hmis_hud_client, data_source: ds1, first_name: 'Spouse', last_name: 'Jones' }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, entry_date: 20.days.ago, relationship_to_hoh: 3, household_id: e1.household_id }
    let!(:e2_assessment) { create(:hmis_intake_assessment, definition: definition, enrollment: e2) }

    # e3 (child): Intake was started with old form, not yet submitted
    let!(:c3) { create :hmis_hud_client, data_source: ds1, first_name: 'Kid 1', last_name: 'Jones' }
    let!(:e3) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c3, entry_date: 1.week.ago, relationship_to_hoh: 2, household_id: e1.household_id }
    let!(:e3_assessment) { create(:hmis_intake_assessment, definition: old_definition, enrollment: e3, wip: true, values: { "entryDate": e3.entry_date.strftime('%Y-%m-%d'), "old_question": 'Previous answer' }) }

    # e4 (child): Intake not yet started
    let!(:c4) { create :hmis_hud_client, data_source: ds1, first_name: 'Kid 2', last_name: 'Jones' }
    let!(:e4) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c4, entry_date: 1.day.ago, relationship_to_hoh: 2, household_id: e1.household_id }

    before(:each) do
      create(:hmis_form_instance, definition: definition, entity: p1) # enable the form in p1
      sign_in(hmis_user)

      visit "/client/#{c1.id}/enrollments/#{e1.id}/assessments"
      click_link 'Intake'
    end

    def select_member(client)
      find('button[role="tab"]', text: client.brief_name).click
      expect(find('button[role="tab"][aria-selected="true"]', text: client.brief_name)).to be_present
    end

    def unlock_household_assessment
      click_button 'Unlock Assessment'
      assert_text 'Save & Submit' # Unlock succeeded
    end

    def submit_household_assessment
      click_button 'Save & Submit'
      assert_text 'This assessment has been submitted' # Submit succeeded
    end

    def save_household_assessment
      click_button 'Save Assessment'
      assert_text(/Last saved [0-9] seconds? ago/) # Save succeeded
    end

    context '[e1] for member with Intake that was submitted using an old form' do
      before(:each) { select_member(c1) }

      it 'opens the assessment with the old form version, and upgrades to new version on unlock' do
        # expect old form
        assert_text old_definition.title
        assert_text 'Entry Date'
        assert_text e1.entry_date.strftime('%m/%d/%Y')

        unlock_household_assessment

        # expect new form
        assert_text definition.title
        assert_text 'New question'
        assert_no_text old_definition.title
        expect(page).to have_field('Entry Date', with: e1.entry_date.strftime('%m/%d/%Y'))
      end

      it 'submits new form fields' do
        assert_text old_definition.title
        unlock_household_assessment

        # fill in the new question and submit, to ensure it is saved
        fill_in 'new_question', with: 'Answer to new question'
        expect do
          submit_household_assessment
        end.to change(e1.custom_assessments, :count).by(0).
          and change(e1_assessment.custom_data_elements, :count).by(1)

        expect(e1_assessment.reload.form_processor.definition_id).to eq(definition.id)
        expect(e1_assessment.custom_data_elements.where(value_string: 'Answer to new question')).to exist
      end
    end

    context '[e2] for member with Intake that was submitted using the new form' do
      before(:each) { select_member(c2) }

      it 'opens with published form' do
        assert_text definition.title
        assert_text 'Entry Date'
        assert_text e2.entry_date.strftime('%m/%d/%Y')
        assert_text 'New question'
      end

      it 'submits with published form' do
        assert_text definition.title
        assert_text 'New question'
        unlock_household_assessment
        fill_in 'new_question', with: 'e2 answer'

        expect do
          submit_household_assessment
        end.to change(e2.custom_assessments, :count).by(0).
          and change(e2_assessment.custom_data_elements, :count).by(1)

        expect(e2_assessment.form_processor.definition_id).to eq(definition.id)
        expect(e2_assessment.custom_data_elements.where(value_string: 'e2 answer')).to exist
      end
    end

    context '[e3] for member with WIP Intake that was started using the old form' do
      before(:each) { select_member(c3) }

      it 'opens with old form in editing mode' do
        assert_text 'This assessment is in progress'
        assert_text old_definition.title
        expect(page).to have_field('Entry Date', with: e3.entry_date.strftime('%m/%d/%Y'))
        expect(page).to have_field('old_question', with: 'Previous answer')
      end

      it 'saves with old form' do
        expect do
          save_household_assessment
        end.not_to change(e3.custom_assessments.in_progress, :count)

        expect(e3_assessment.form_processor.definition_id).to eq(old_definition.id)
      end
    end

    context '[e4] for member with no intake' do
      before(:each) { select_member(c4) }

      it 'opens with new form in editing mode' do
        assert_text 'This assessment has not been started'
        assert_text definition.title
        assert_text 'New question'
      end

      it 'saves with new form' do
        fill_in 'new_question', with: 'Answer to new question'
        expect do
          save_household_assessment
        end.to change(e4.custom_assessments.in_progress, :count).by(1)

        # Ensure the form processor is using the new definition
        expect(e4.intake_assessment.form_processor.definition_id).to eq(definition.id)
      end
    end
  end
end
