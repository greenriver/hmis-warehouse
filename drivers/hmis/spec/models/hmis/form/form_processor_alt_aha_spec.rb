###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::FormProcessor, type: :model do
  include_context 'hmis base setup'

  let(:client) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1 }

  let(:definition_json) do
    {
      item: [
        {
          type: 'INTEGER',
          component: 'ALT_AHA',
          link_id: 'alt_aha_score',
          text: 'Alt AHA Score',
          mapping: {
            custom_field_key: 'housing_needs_alt_aha_score',
          },
        },
      ],
    }
  end

  let!(:definition) do
    create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: definition_json
  end

  # Backing CDE so the custom field is recognized; calculator behavior is mocked
  let!(:cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'housing_needs_alt_aha_score',
      data_source: ds1,
      field_type: :integer,
    )
  end

  def build_assessment
    Hmis::Hud::CustomAssessment.new_with_defaults(
      enrollment: enrollment,
      user: u1,
      form_definition: definition,
      assessment_date: Date.yesterday,
    )
  end

  describe 'Alt AHA score validation' do
    let(:submitted_score) { 0 }
    let(:computed_score) { 6 }

    let(:assessment) do
      assessment = build_assessment
      assessment.form_processor.hud_values = { 'housing_needs_alt_aha_score' => submitted_score }
      assessment.form_processor.values = { 'alt_aha_score' => submitted_score }
      assessment
    end

    before do
      # Stub `calculate_components` so `calculate_score` runs and writes a CalculationLog
      stubbed_result = { raw_score: 0.0, probability: 0.0, points: 2, intercept: 0.0 }
      components = { alt_aha_1: stubbed_result, alt_aha_2: stubbed_result, alt_aha_3: stubbed_result }
      allow_any_instance_of(HmisExternalApis::AcHmis::AltAhaCalculator).
        to receive(:calculate_components).and_return(components) # total_points = (2+0) * 3 = 6
    end

    context 'when submitted value does not match computed score' do
      let(:submitted_score) { 9 }

      it 'returns a validation error' do
        assessment.form_processor.run!(user: hmis_user)
        expect(assessment.form_processor.processing_errors.errors.first.full_message).to eq('Alt AHA Score value has changed, and needs to be recalculated before submission')
        # Doesn't save a CalculationLog since the assessment was not saved
      end
    end

    context 'when submitted value matches computed score' do
      let(:submitted_score) { 6 }

      it 'does not raise and persists the value' do
        expect do
          assessment.form_processor.run!(user: hmis_user)
          assessment.save_not_in_progress
        end.to change(Hmis::Hud::CustomDataElement, :count).by(1).
          and change(Hmis::Scoring::CalculationLog, :count).by(1)

        cde = Hmis::Hud::CustomDataElement.of_type(cded).sole
        expect(cde.value_integer).to eq(6)
        log = Hmis::Scoring::CalculationLog.last
        expect(log.namespace).to eq('alt_aha')
        expect(log.final_score).to eq(6)
        expect(log.owner).to eq(enrollment)
      end
    end
  end

  describe 'Alt AHA score validation on model version 2' do
    let(:definition_json) do
      {
        item: [
          { type: 'DATE', link_id: 'assessment_date', text: 'Assessment Date', assessment_date: true },
          { type: 'INTEGER', link_id: 'q1', text: 'Question 1' },
          {
            type: 'INTEGER',
            component: 'ALT_AHA',
            link_id: 'alt_aha_score',
            text: 'Alt AHA Score',
            mapping: { custom_field_key: 'housing_needs_alt_aha_score' },
          },
        ],
      }
    end

    let(:assessment) do
      assessment = build_assessment
      assessment.form_processor.hud_values = { 'housing_needs_alt_aha_score' => submitted_score }
      assessment.form_processor.values = { 'assessment_date' => '2026-10-28', 'q1' => 5, 'alt_aha_score' => submitted_score }
      assessment
    end

    before do
      AppConfigProperty.create!(key: 'ac_hmis/alt_aha_model_version', value_input: '2')
    end

    context 'when the rules fit the definition' do
      # A weight of 0 leaves each algorithm at its intercept, which scores 3 overall
      before do
        ['alt_aha_1', 'alt_aha_2', 'alt_aha_3', 'alt_aha_4'].each do |algorithm|
          create(:hmis_scoring_rule, :v2, link_id: 'q1', form_definition_identifier: definition.identifier, weight: 0, algorithm: algorithm)
        end
      end

      context 'when submitted value matches the v2 score' do
        let(:submitted_score) { 3 }

        it 'does not add a processing error' do
          assessment.form_processor.run!(user: hmis_user)
          expect(assessment.form_processor.processing_errors).to be_nil
        end
      end

      context 'when submitted value does not match the v2 score' do
        let(:submitted_score) { 6 }

        it 'returns a validation error' do
          assessment.form_processor.run!(user: hmis_user)
          expect(assessment.form_processor.processing_errors.errors.first.full_message).to eq('Alt AHA Score value has changed, and needs to be recalculated before submission')
        end
      end
    end

    context 'when a rule question is not on the definition' do
      let(:submitted_score) { 3 }

      before do
        create(:hmis_scoring_rule, :v2, link_id: 'new_question', form_definition_identifier: definition.identifier, algorithm: 'alt_aha_1')
      end

      it 'raises through the guard' do
        expect { assessment.form_processor.run!(user: hmis_user) }.to raise_error(/not on form definition #{definition.id}: new_question/)
      end
    end
  end
end
