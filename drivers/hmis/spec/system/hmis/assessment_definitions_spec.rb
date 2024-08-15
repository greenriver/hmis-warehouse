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
    let!(:definition) { create :custom_assessment_with_custom_fields_and_rules, title: 'Very Custom Assessment', data_source: ds1 }
    let!(:old_definition) do
      fd = create(:custom_assessment_with_custom_fields_and_rules, identifier: definition.identifier, title: 'Previous Very Custom Assessment', data_source: ds1, version: 0, status: :retired)
      fd.definition['item'][0]['item'] << { 'type': 'DISPLAY', 'link_id': 'old_message', 'text': 'Text on old form' }
      fd.save!
      fd
    end

    before(:each) do
      create(:hmis_form_instance, definition: definition, entity: p1) # enable the form in p1
      sign_in(hmis_user)
      disable_transitions

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
        assert_no_text old_definition.title
        assert_text definition.title
        expect(page).to have_field('Assessment Date', with: assessment.assessment_date.strftime('%m/%d/%Y'))
        assert_no_text 'Text on old form'
      end
    end

    context 'with an existing WIP assessment that was created with an old definition' do
      let!(:wip_assessment) { create(:hmis_custom_assessment, definition: old_definition, wip: true, values: { 'assessment_date': today.strftime('%Y-%m-%d') }, enrollment: e1, assessment_date: today) }

      it 'uses old form version for editing' do
        click_link old_definition.title
        assert_text old_definition.title
        expect(page).to have_field('Assessment Date', with: wip_assessment.assessment_date.strftime('%m/%d/%Y'))
        assert_text 'Text on old form'
      end
    end
  end

  # Test context for viewing/editing a "household assessment" using an Intake form
  # Household contains 4 members each with differently configured assessments, to ensure
  # that the correct form version is used for each member, even in the Household Assessments view.
  context 'Performing Household Intake assessments with various definition versions' do
    let!(:definition) { create :hmis_intake_assessment_definition, title: 'New Special Intake' }
    let!(:old_definition) do
      fd = create(:hmis_intake_assessment_definition, identifier: definition.identifier, title: 'Old Special Intake', version: 0, status: :retired)
      fd.definition['item'][0]['item'] << { 'type': 'DISPLAY', 'link_id': 'old_message', 'text': 'Text on old form' }
      fd.save!
      fd
    end

    # e1 (HoH): Intake was Submitted with old form
    let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Parent', last_name: 'Jones' }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 2.months.ago, relationship_to_hoh: 1 }
    let!(:e1_assessment) { create(:hmis_intake_assessment, definition: old_definition, enrollment: e1) }

    # e2 (spouse): Intake was Submitted with published form
    let!(:c2) { create :hmis_hud_client, data_source: ds1, first_name: 'Spouse', last_name: 'Jones' }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, entry_date: 1.month.ago, relationship_to_hoh: 3, household_id: e1.household_id }
    let!(:e2_assessment) { create(:hmis_intake_assessment, definition: definition, enrollment: e2) }

    # e3 (child): Intake was started with old form, not yet submitted
    let!(:c3) { create :hmis_hud_client, data_source: ds1, first_name: 'Kid 1', last_name: 'Jones' }
    let!(:e3) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c3, entry_date: 1.week.ago, relationship_to_hoh: 2, household_id: e1.household_id }
    let!(:e3_assessment) { create(:hmis_intake_assessment, definition: old_definition, enrollment: e3, wip: true, values: { "entryDate": e3.entry_date.strftime('%Y-%m-%d') }) }

    # e4 (child): Intake not yet started
    let!(:c4) { create :hmis_hud_client, data_source: ds1, first_name: 'Kid 2', last_name: 'Jones' }
    let!(:e4) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c4, entry_date: 1.day.ago, relationship_to_hoh: 2, household_id: e1.household_id }

    before(:each) do
      create(:hmis_form_instance, definition: definition, entity: p1) # enable the form in p1
      sign_in(hmis_user)
      disable_transitions

      visit "/client/#{c1.id}/enrollments/#{e1.id}/assessments"
      click_link 'Intake'
    end

    context '[e1] for member with Intake that was submitted using an old form' do
      it 'opens the assessment with the old form version, and upgrades to new version on unlock' do
        # expect old form
        assert_text old_definition.title
        assert_text 'Text on old form'
        assert_text 'Entry Date'
        assert_text e1.entry_date.strftime('%m/%d/%Y')

        click_button('Unlock Assessment', match: :first)
        # expect new form
        assert_no_text old_definition.title
        assert_no_text 'Text on old form'
        assert_text definition.title
        expect(page).to have_field('Entry Date', with: e1.entry_date.strftime('%m/%d/%Y'))
      end
    end

    context '[e2] for member with Intake that was submitted using the new form' do
      it 'opens with published form' do
        find('button[role="tab"]', text: c2.brief_name).click

        assert_text definition.title
        assert_no_text 'Text on old form'
        assert_text 'Entry Date'
        assert_text e2.entry_date.strftime('%m/%d/%Y')
      end
    end

    context '[e3] for member with WIP Intake that was started using the old form' do
      it 'opens with old form in editing mode' do
        find('button[role="tab"]', text: c3.brief_name).click

        assert_text 'This assessment is in progress'
        assert_text old_definition.title
        assert_text 'Text on old form'
        expect(page).to have_field('Entry Date', with: e3.entry_date.strftime('%m/%d/%Y'))
      end
    end

    context '[e4] for member with no intake' do
      it 'opens with new form in editing mode' do
        find('button[role="tab"]', text: c4.brief_name).click

        assert_text 'This assessment has not been started'
        assert_text definition.title
        assert_no_text 'Text on old form'
      end
    end
  end
end
