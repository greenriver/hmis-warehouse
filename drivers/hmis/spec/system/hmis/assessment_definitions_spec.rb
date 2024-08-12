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
  #   Opened for Editing
  #      Uses the newer published version
  #
  # Household: Intake
  # Household: Exit
  # Locations to test assessment forms:
  # - Individual (existing)
  # - Individual (new)
  # - Household (new)
  # - Household (some existing of previous versions)
  context 'For CustomAssessment FormDefinition with multiple versions' do
    let!(:definition) { create :custom_assessment_with_custom_fields_and_rules, title: 'Very Custom Assessment', data_source: ds1 }
    let!(:old_definition) do
      fd = create(:custom_assessment_with_custom_fields_and_rules, identifier: definition.identifier, title: 'Previous Very Custom Assessment', data_source: ds1, version: 0, status: :retired)
      fd.definition['item'][0]['item'] << { 'type': 'DISPLAY', 'link_id': 'old_message', 'text': 'Text on old form' }
      fd.save!
      fd
    end
    let!(:assessment) { create(:hmis_custom_assessment, definition: old_definition, enrollment: e1, client: c1, assessment_date: today) }

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

    it 'creates a new assessment with the most recent form version' do
      click_button 'New Assessment'
      click_link definition.title

      mui_date_select 'Assessment Date', date: today

      expect do
        submit_assessment
      end.to change(e1.custom_assessments, :count).by(1).
        and change(e1.custom_assessments.not_in_progress.
          with_form_definition_identifier(definition.identifier).
          where(assessment_date: today), :count).by(1).
        and change(Hmis::Hud::CustomDataElement, :count).by(0)
    end

    # TODO add case: existing WIP assessment
    context 'opening an existing (submitted) assessment' do
      let!(:assessment) { create(:hmis_custom_assessment, definition: old_definition, enrollment: e1, client: c1, assessment_date: today) }

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

    context 'opening an existing WIP assessment' do
      let!(:assessment) { create(:hmis_wip_custom_assessment, definition: old_definition, enrollment: e1, client: c1, assessment_date: today) }

      it 'uses old form version for editing' do
        click_link old_definition.title

        assert_text old_definition.title

        # unlock the assessment should upgrade to the newer form
        # click_button('Unlock Assessment', match: :first)
        # assert_no_text old_definition.title
        # assert_text definition.title
        expect(page).to have_field('Assessment Date', with: assessment.assessment_date.strftime('%m/%d/%Y'))
        assert_text 'Text on old form'
      end
    end
  end

  # TODO: Household Intake
  #
  context 'Household Intake assessments' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Parent', last_name: 'Jones' }
    let!(:c2) { create :hmis_hud_client, data_source: ds1, first_name: 'Kid', last_name: 'Jones' }
    let!(:c3) { create :hmis_hud_client, data_source: ds1, first_name: 'Kid 2', last_name: 'Jones' }

    let!(:e1) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 1.month.ago, relationship_to_hoh: 1 }
    let!(:e2) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, entry_date: 1.month.ago, relationship_to_hoh: 2, household_id: e1.household_id }
    let!(:e3) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c3, entry_date: 1.month.ago, relationship_to_hoh: 2, household_id: e1.household_id }

    let!(:definition) { create :hmis_intake_assessment_definition, title: 'Special Intake', data_source: ds1 }
    let!(:old_definition) do
      fd = create(:hmis_intake_assessment_definition, identifier: definition.identifier, title: 'Previous Special Intake', data_source: ds1, version: 0, status: :retired)
      fd.definition['item'][0]['item'] << { 'type': 'DISPLAY', 'link_id': 'old_message', 'text': 'Text on old form' }
      fd.save!
      fd
    end
    # let!(:definition) { create :custom_assessment_with_custom_fields_and_rules, title: 'Very Custom Assessment', data_source: ds1 }
    let!(:e1_assessment) { create(:hmis_custom_assessment, definition: definition, enrollment: e1, client: c1, assessment_date: today) }
    let!(:e2_assessment) { create(:hmis_custom_assessment, definition: old_definition, enrollment: e1, client: c1, assessment_date: today) }

    before(:each) do
      create(:hmis_form_instance, definition: definition, entity: p1) # enable the form in p1
      sign_in(hmis_user)
      disable_transitions

      visit "/client/#{c1.id}/enrollments/#{e1.id}/assessments"
    end

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
  # TODO: Household Exit?
end
