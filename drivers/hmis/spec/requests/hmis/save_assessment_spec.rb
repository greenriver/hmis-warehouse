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
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    hmis_login(user)
  end

  let(:test_input) do
    {
      enrollment_id: e1.id.to_s,
      form_definition_id: fd1.id,
      assessment_date: (Date.today - 2.days).strftime('%Y-%m-%d'),
      values: { key: 'value' },
    }
  end

  let(:mutation) do
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

  let(:get_enrollment_query) do
    <<~GRAPHQL
      query GetEnrollment($id: ID!) {
        enrollment(id: $id) {
          assessments {
            nodesCount
            nodes {
              id
              inProgress
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should create and update a WIP assessment successfully' do
    # Create new WIP assessment
    response, result = post_graphql(**test_input) { mutation }
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      expect(errors).to be_empty
      expect(assessment).to be_present
      expect(assessment['enrollment']).to be_present
      expect(assessment).to include(
        'inProgress' => true,
        'assessmentDate' => test_input[:assessment_date],
        'assessmentDetail' => include('values' => { 'key' => 'value' }),
      )
      expect(Hmis::Hud::Assessment.count).to eq(1)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)
      expect(Hmis::Hud::Assessment.where(enrollment_id: Hmis::Hud::Assessment::WIP_ID).count).to eq(1)
      expect(Hmis::Wip.count).to eq(1)
      expect(Hmis::Wip.first).to have_attributes(enrollment_id: e1.id, client_id: c1.id, project_id: nil)
      expect(Hmis::Hud::Assessment.viewable_by(hmis_user).count).to eq(1)
    end

    # WIP assessment should appear on enrollment query
    response, result = post_graphql(id: e1.id) { get_enrollment_query }
    expect(response.status).to eq 200
    enrollment = result.dig('data', 'enrollment')
    expect(enrollment).to be_present
    expect(enrollment.dig('assessments', 'nodes', 0, 'id')).to eq(assessment['id'])
  end

  it 'update an existing WIP assessment successfully' do
    # Create new WIP assessment
    response, result = post_graphql(**test_input) { mutation }
    assessment_id = result.dig('data', 'saveAssessment', 'assessment', 'id')
    expect(assessment_id).to be_present
    expect(Hmis::Hud::Assessment.count).to eq(1)
    expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)

    # Subsequent request should update the existing WIP assessment
    response, result = post_graphql(assessment_id: assessment_id, values: { key: 'newValue', newKey: 'foo' }) { mutation }
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      expect(errors).to be_empty
      expect(assessment).to be_present
      expect(assessment['enrollment']).to be_present
      expect(assessment).to include(
        'inProgress' => true,
        'assessmentDetail' => include('values' => { 'key' => 'newValue', 'newKey' => 'foo' }),
      )
      expect(Hmis::Hud::Assessment.count).to eq(1)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)
      expect(Hmis::Wip.count).to eq(1)
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if enrollment doesn\'t exist',
        ->(input) { input.merge(enrollment_id: '999') },
        {
          'message' => 'Enrollment must exist',
          'attribute' => 'enrollmentId',
        },
      ],
      [
        'should emit error if cannot find form definition',
        ->(input) { input.merge(form_definition_id: '999') },
        {
          'message' => 'Form definition must exist',
          'attribute' => 'formDefinitionId',
        },
      ],
      [
        'should emit error if cannot find assessment',
        ->(input) { input.merge(assessment_id: '999') },
        {
          'message' => 'Assessment must exist',
          'attribute' => 'assessmentId',
        },
      ],
      [
        'should emit error if neithor enrollment nor assessment are provided',
        ->(input) { input.except(:enrollment_id, :assessment_id) },
        {
          'message' => 'Enrollment ID or Assessment ID must exist',
          'attribute' => 'enrollmentId',
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input) { mutation }
        errors = result.dig('data', 'saveAssessment', 'errors')
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
