###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::AcHmis::CalculateAltAhaScore, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  let!(:form_definition) do
    definition = {
      "item": [
        { "link_id": 'required_q1', "type": 'STRING' },
        { "link_id": 'required_q2', "type": 'INTEGER' },
        { "link_id": 'optional_q', "type": 'STRING' },
      ],
    }
    create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: definition, identifier: 'test_aha_form', status: :published, data_source: ds1)
  end

  before(:each) do
    hmis_login(user)
    # Mock AHA being enabled
    allow(HmisExternalApis::AcHmis::Aha).to receive(:enabled?).and_return(true)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation($enrollmentId: ID!, $formDefinitionIdentifier: String!, $valuesByLinkId: JsonObject!) {
        calculateAltAhaScore(enrollmentId: $enrollmentId, formDefinitionIdentifier: $formDefinitionIdentifier, valuesByLinkId: $valuesByLinkId) {
          score
          errors { fullMessage }
        }
      }
    GRAPHQL
  end

  let(:input) do
    {
      enrollmentId: e1.id,
      formDefinitionIdentifier: form_definition.identifier,
      valuesByLinkId: { 'required_q1' => 'answer1', 'required_q2' => 42 },
    }
  end

  describe 'calculateAltAhaScore' do
    context 'when AHA is not enabled' do
      it 'raises an error' do
        allow(HmisExternalApis::AcHmis::Aha).to receive(:enabled?).and_return(false)

        expect_gql_error post_graphql(input) { mutation }
      end
    end

    context 'when calculator is enabled' do
      let(:mock_calculator) { instance_double(HmisExternalApis::AcHmis::AltAhaCalculator) }

      before do
        allow(HmisExternalApis::AcHmis::AltAhaCalculator).to receive(:new).and_return(mock_calculator)
        allow(mock_calculator).to receive(:required_link_ids).and_return(['required_q1', 'required_q2'])
        allow(Hmis::Form::Definition).to receive_message_chain(:published, :in_data_source, :find_by).and_return(form_definition)
      end

      it 'returns error message when not all required responses are provided' do
        # Mock the form validation to return validation errors
        allow(form_definition).to receive(:validate_form_values).and_return(
          [HmisErrors::Error.new(:required_q1, :required, severity: :error, link_id: 'required_q1')],
        )

        response, result = post_graphql(input) { mutation }

        expect(response.status).to eq(200), result.inspect
        errors = result.dig('data', 'calculateAltAhaScore', 'errors')
        score = result.dig('data', 'calculateAltAhaScore', 'score')

        expect(score).to be_nil
        expect(errors).to be_present
        expect(errors.first['fullMessage']).to eq('Unable to calculate score. Please finish entering responses.')
      end

      it 'successfully calculates score when all required responses are provided' do
        # Mock successful validation and score calculation
        allow(form_definition).to receive(:validate_form_values).and_return([])
        allow(mock_calculator).to receive(:calculate_score).and_return([75, nil])

        response, result = post_graphql(input) { mutation }

        expect(response.status).to eq(200), result.inspect
        errors = result.dig('data', 'calculateAltAhaScore', 'errors')
        score = result.dig('data', 'calculateAltAhaScore', 'score')

        expect(errors).to be_empty
        expect(score).to eq(75)
      end

      context 'permissions' do
        it 'denies access if user cannot edit the enrollment' do
          remove_permissions(access_control, :can_edit_enrollments)

          expect_access_denied post_graphql(input) { mutation }
        end
      end
    end

    context 'when the model version is 2' do
      let!(:form_definition) do
        definition = {
          "item": [
            { "link_id": 'assessment_date', "type": 'DATE', "text": 'Assessment Date', "assessment_date": true },
            { "link_id": 'q1', "type": 'INTEGER', "text": 'Question 1' },
          ],
        }
        create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: definition, identifier: 'test_aha_form', status: :published, data_source: ds1)
      end

      # A weight of 0 leaves each algorithm at its intercept, which scores 3 overall
      let!(:rules) do
        ['alt_aha_1', 'alt_aha_2', 'alt_aha_3', 'alt_aha_4'].map do |algorithm|
          create(:hmis_scoring_rule, :v2, link_id: 'q1', form_definition_identifier: 'test_aha_form', weight: 0, algorithm: algorithm)
        end
      end

      before do
        AppConfigProperty.create!(key: 'ac_hmis/alt_aha_model_version', value_input: '2')
      end

      it 'returns the v2 score' do
        input = { enrollmentId: e1.id, formDefinitionIdentifier: 'test_aha_form', valuesByLinkId: { 'assessment_date' => '2026-10-28', 'q1' => 5 } }

        expect do
          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'calculateAltAhaScore', 'errors')).to be_empty
          expect(result.dig('data', 'calculateAltAhaScore', 'score')).to eq(3)
        end.to change(Hmis::Scoring::CalculationLog, :count).by(1)

        expect(Hmis::Scoring::CalculationLog.last.calculation_details['model_version']).to eq(2)
      end

      it 'returns the generic error when the assessment date is blank' do
        input = { enrollmentId: e1.id, formDefinitionIdentifier: 'test_aha_form', valuesByLinkId: { 'assessment_date' => nil, 'q1' => 5 } }

        expect do
          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'calculateAltAhaScore', 'score')).to be_nil
          expect(result.dig('data', 'calculateAltAhaScore', 'errors', 0, 'fullMessage')).to eq('Unable to calculate score. Please finish entering responses.')
        end.not_to change(Hmis::Scoring::CalculationLog, :count)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
