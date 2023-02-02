require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:test_input) do
    {
      enrollment_id: e1.id,
      form_definition_id: fd1.id,
      assessment_date: '2022-10-16',
      values: { 'key' => 'value' },
      hud_values: { 'hud_key' => 'hud_value' },
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation SubmitAssessment($input: SubmitAssessmentInput!) {
        submitAssessment(input: $input) {
          assessment {
            #{scalar_fields(Types::HmisSchema::Assessment)}
            enrollment {
              id
            }
            user {
              id
            }
            client {
              id
            }
            assessmentDetail {
              #{scalar_fields(Types::HmisSchema::AssessmentDetail)}
              definition {
                id
              }
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'Submitting a form for the first time' do
    it 'should create assessment successfully' do
      response, result = post_graphql(input: test_input) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessment['id']).to be_present
        expect(assessment['assessmentDate']).to eq(test_input[:assessment_date])
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
        expect(Hmis::Hud::Assessment.first.enrollment_id).to eq(e1.enrollment_id)
        details = Hmis::Hud::Assessment.first.assessment_detail
        expect(details.values).to include(test_input[:values])
        expect(details.hud_values).to include(test_input[:hud_values])
      end
    end
  end

  describe 'Re-Submitting a form that has already been submitted' do
    before(:each) do
      # create tha initial submitted assessment
      post_graphql(input: test_input) { mutation }
      @assessment = Hmis::Hud::Assessment.first
    end

    it 'should update assessment successfully' do
      input = { assessment_id: @assessment.id, values: { 'newKey' => 'newValue' }, hud_values: { 'newHudKey' => 'newHudValue' } }
      response, result = post_graphql(input: input) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessment['id']).to be_present
        expect(assessment['assessmentDate']).to eq(test_input[:assessment_date])
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
        details = Hmis::Hud::Assessment.first.assessment_detail
        expect(details.values).to include(input[:values])
        expect(details.hud_values).to include(input[:hud_values])
      end
    end
  end

  describe 'Submitting a form that was previously saved as WIP' do
    let(:save_wip_mutation) do
      <<~GRAPHQL
        mutation SaveAssessment($enrollmentId: ID, $formDefinitionId: ID, $assessmentId: ID, $values: JsonObject!, $assessmentDate: String) {
          saveAssessment(input: {
            enrollmentId: $enrollmentId,
            formDefinitionId: $formDefinitionId,
            assessmentId: $assessmentId,
            assessmentDate: $assessmentDate,
            values: $values,
          }) {
            assessment {
              id
            }
          }
        }
      GRAPHQL
    end
    before(:each) do
      # create the initial WIP assessment
      post_graphql(input: test_input.except(:hud_values)) { save_wip_mutation }
      @assessment = Hmis::Hud::Assessment.in_progress.first
    end

    it 'should update and submit assessment successfully' do
      expect(Hmis::Hud::Assessment.count).to eq(1)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)

      input = { assessment_id: @assessment.id, values: { 'newKey' => 'newValue' }, hud_values: { 'newHudKey' => 'newHudValue' } }
      response, result = post_graphql(**input) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessment).to be_present
        expect(assessment['enrollment']).to be_present
        expect(assessment['assessmentDate']).to eq(test_input[:assessment_date])
        expect(assessment['inProgress']).to eq(false)
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
        expect(Hmis::Hud::Assessment.where(enrollment_id: Hmis::Hud::Assessment::WIP_ID).count).to eq(0)
        expect(Hmis::Wip.count).to eq(0)

        details = Hmis::Hud::Assessment.first.assessment_detail
        expect(details.values).to include(input[:values])
        expect(details.hud_values).to include(input[:hud_values])
      end
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if assessment doesn\'t exist',
        ->(input) { input.merge(assessment_id: '999') },
        {
          'fullMessage' => 'Assessment must exist',
          'attribute' => 'assessmentId',
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input: input) { mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(errors).to contain_exactly(*expected_errors.map { |error_attrs| include(**error_attrs) })
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
