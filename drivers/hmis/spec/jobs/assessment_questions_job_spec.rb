###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::AssessmentQuestionsJob, type: :model do
  context 'generates AssessmentQuestions' do
    let!(:ds1) { create(:hmis_data_source) }

    # Repeat-string field
    let!(:cded_str) { create :hmis_custom_data_element_definition, label: 'Multiple strings', data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment', repeats: true }

    # Boolean field
    let!(:cded_bool) { create :hmis_custom_data_element_definition, label: 'A bool', data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment', field_type: :boolean, repeats: false }
    # let!(:cde2) { create :hmis_custom_data_element, data_element_definition: cded2, owner: c1, data_source: ds1, value_boolean: true }

    # Integer field
    let!(:cded_int) { create :hmis_custom_data_element_definition, label: 'A number', data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment', field_type: :integer }

    # cruft: unrelated cded on custom assessment
    let!(:cded_cruft) { create :hmis_custom_data_element_definition, label: 'CDED not in assessment', data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment', field_type: :string }

    let!(:ce_definition) do
      form_content = {
        'item': [
          {
            'type': 'GROUP',
            'link_id': 'group_1',
            'text': 'Section 1',
            'item': [
              {
                'type': 'STRING',
                'link_id': 'question_one',
                'repeats': true,
                'mapping': { 'custom_field_key': cded_str.key },
              },
              {
                # cruft
                'type': 'DISPLAY',
                'link_id': 'display',
                'text': 'This is a display item',
              },
            ],
          },
          {
            'type': 'GROUP',
            'link_id': 'group_2',
            'text': 'Section 2',
            'item': [
              {
                'type': 'BOOLEAN',
                'link_id': 'question_two',
                'mapping': { 'custom_field_key': cded_bool.key },
              },
              {
                # cruft
                'type': 'STRING',
                'link_id': 'field',
                'mapping': { 'field_name': 'ignored' },
              },
              {
                'type': 'GROUP',
                'link_id': 'group_inner',
                'item': [
                  {
                    'type': 'INTEGER',
                    'link_id': 'question_three',
                    'mapping': { 'custom_field_key': cded_int.key },
                  },
                ],
              },
            ],
          },
        ],
      }
      create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: form_content)
    end

    let!(:u1) { create :hmis_hud_user, data_source: ds1 }
    let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:ce_assessment) { create(:hmis_hud_assessment, data_source: ds1, enrollment: e1, client: c1) }
    let!(:custom_assessment) do
      ca = create(:hmis_custom_assessment, definition: ce_definition, data_source: ds1, enrollment: e1, client: c1)
      ca.form_processor.update!(ce_assessment: ce_assessment)
      ca
    end

    describe 'when responses do not exist' do
      let!(:cde_str1) { create :hmis_custom_data_element, data_element_definition: cded_str, owner: custom_assessment, data_source: ds1, value_string: 'response' }

      it 'creates AssessmentQuestions with some empty values' do
        expect do
          Hmis::AssessmentQuestionsJob.perform_now(custom_assessment_ids: custom_assessment.id)
        end.to change(ce_assessment.assessment_questions, :count).by(3)

        expect(ce_assessment.assessment_questions.map(&:attributes)).to contain_exactly(
          a_hash_including('AssessmentQuestion' => cded_str.key, 'AssessmentAnswer' => '["response"]'),
          a_hash_including('AssessmentQuestion' => cded_bool.key, 'AssessmentAnswer' => 'No'), # nil boolean response gets stored as No
          a_hash_including('AssessmentQuestion' => cded_int.key, 'AssessmentAnswer' => nil),
        )
      end
    end

    describe 'when all responses exist' do
      # responses for cded_str
      let!(:cde_str1) { create :hmis_custom_data_element, data_element_definition: cded_str, owner: custom_assessment, data_source: ds1, value_string: 'First value' }
      let!(:cde_str2) { create :hmis_custom_data_element, data_element_definition: cded_str, owner: custom_assessment, data_source: ds1, value_string: 'Second value' }
      # response for cded_bool
      let!(:cde_bool) { create :hmis_custom_data_element, data_element_definition: cded_bool, owner: custom_assessment, data_source: ds1, value_boolean: true }
      # response for cded_int
      let!(:cde_int) { create :hmis_custom_data_element, data_element_definition: cded_int, owner: custom_assessment, data_source: ds1, value_integer: 6 }

      it 'creates AssessmentQuestions with correct group and order' do
        expect do
          Hmis::AssessmentQuestionsJob.perform_now(custom_assessment_ids: custom_assessment.id)
        end.to change(ce_assessment.assessment_questions, :count).by(3)

        expect(ce_assessment.assessment_questions.map(&:attributes)).to contain_exactly(
          a_hash_including(
            'AssessmentQuestion' => cded_str.key,
            'AssessmentAnswer' => '["First value", "Second value"]',
            'AssessmentQuestionGroup' => 'Section 1',
            'AssessmentQuestionOrder' => 1,
          ),
          a_hash_including(
            'AssessmentQuestion' => cded_bool.key,
            'AssessmentAnswer' => 'Yes',
            'AssessmentQuestionGroup' => 'Section 2',
            'AssessmentQuestionOrder' => 2,
          ),
          a_hash_including(
            'AssessmentQuestion' => cded_int.key,
            'AssessmentAnswer' => '6',
            'AssessmentQuestionGroup' => 'Section 2',
            'AssessmentQuestionOrder' => 3,
          ),
        )
      end

      it 'can re-process changed values' do
        # create AssessmentQuestions
        expect do
          Hmis::AssessmentQuestionsJob.perform_now(custom_assessment_ids: custom_assessment.id)
        end.to change(ce_assessment.assessment_questions, :count).by(3)
        bool_question = ce_assessment.assessment_questions.find_by(assessment_question: cded_bool.key)
        expect(bool_question.AssessmentAnswer).to eq('Yes')

        # change a response value
        cde_bool.update!(value_boolean: false)

        # re-run the job
        expect do
          Hmis::AssessmentQuestionsJob.perform_now(custom_assessment_ids: custom_assessment.id)
        end.to change(ce_assessment.assessment_questions, :count).by(0)

        bool_question = ce_assessment.assessment_questions.find_by(assessment_question: cded_bool.key)
        expect(bool_question.AssessmentAnswer).to eq('No')
      end
    end

    describe 'for multiple custom assessments with different definitions' do
      let!(:cded_str_2) { create :hmis_custom_data_element_definition, data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment' }
      let!(:ce_definition_2) do
        form_content = {
          'item': [
            {
              'type': 'GROUP',
              'link_id': 'fd2_group1',
              'text': 'Foo',
              'item': [
                {
                  'type': 'STRING',
                  'link_id': 'fd2_question1',
                  'repeats': true,
                  'mapping': { 'custom_field_key': cded_str_2.key },
                },
              ],
            },
          ],
        }
        create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: form_content)
      end
      let!(:ce_assessment_2) { create(:hmis_hud_assessment, data_source: ds1, enrollment: e1, client: c1) }
      let!(:custom_assessment_2) do
        ca = create(:hmis_custom_assessment, definition: ce_definition_2, data_source: ds1, enrollment: e1, client: c1)
        ca.form_processor.update!(ce_assessment: ce_assessment_2)
        ca
      end
      let!(:cde_str1) { create :hmis_custom_data_element, data_element_definition: cded_str_2, owner: custom_assessment_2, data_source: ds1, value_string: 'other form response' }

      it 'can run on a batch of Custom Assessments that use different definitions' do
        expect do
          Hmis::AssessmentQuestionsJob.perform_now(custom_assessment_ids: [custom_assessment.id, custom_assessment_2.id])
        end.to change(ce_assessment.assessment_questions, :count).by(3).
          and change(ce_assessment_2.assessment_questions, :count).by(1)

        expect(ce_assessment.assessment_questions.map(&:attributes)).to contain_exactly(
          a_hash_including(
            'AssessmentQuestion' => cded_str.key,
            'AssessmentAnswer' => nil,
            'AssessmentQuestionGroup' => 'Section 1',
            'AssessmentQuestionOrder' => 1,
          ),
          a_hash_including(
            'AssessmentQuestion' => cded_bool.key,
            'AssessmentAnswer' => 'No', # nil boolean response gets stored as No
            'AssessmentQuestionGroup' => 'Section 2',
            'AssessmentQuestionOrder' => 2,
          ),
          a_hash_including(
            'AssessmentQuestion' => cded_int.key,
            'AssessmentAnswer' => nil,
            'AssessmentQuestionGroup' => 'Section 2',
            'AssessmentQuestionOrder' => 3,
          ),
        )

        expect(ce_assessment_2.assessment_questions.map(&:attributes)).to contain_exactly(
          a_hash_including(
            'AssessmentQuestion' => cded_str_2.key,
            'AssessmentAnswer' => 'other form response',
            'AssessmentQuestionGroup' => 'Foo',
            'AssessmentQuestionOrder' => 1,
          ),
        )
      end
    end
  end
end
