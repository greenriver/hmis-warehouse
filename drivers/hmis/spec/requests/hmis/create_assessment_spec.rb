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
      mutation CreateAssessment($enrollmentId: ID!, $formDefinitionId: ID!, $values: JsonObject!, $assessmentDate: String, $inProgress: Boolean) {
        createAssessment(input: {
          enrollmentId: $enrollmentId,
          formDefinitionId: $formDefinitionId,
          assessmentDate: $assessmentDate,
          values: $values,
          inProgress: $inProgress,
        }) {
          assessment {
            id
            inProgress
            enrollment {
              id
            }
            user {
              id
            }
            client {
              id
            }
            assessmentDate
            assessmentLocation
            assessmentType
            assessmentLevel
            prioritizationStatus
            dateCreated
            dateUpdated
            dateDeleted
            assessmentDetail {
              id
              definition {
                id
                version
                role
                status
                identifier
                definition {
                  item {
                    linkId
                  }
                }
              }
              dataCollectionStage
              role
              status
              values
            }
          }
          errors {
            attribute
            message
            fullMessage
            type
            options
            __typename
          }
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

  it 'should create an assessment successfully' do
    response, result = post_graphql(**test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      assessment = result.dig('data', 'createAssessment', 'assessment')
      errors = result.dig('data', 'createAssessment', 'errors')
      expect(assessment['id']).to be_present
      expect(errors).to be_empty

      # assessment should appear on enrollment query
      response, result = post_graphql(id: e1.id) { get_enrollment_query }
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'enrollment')
      expect(enrollment).to be_present
      expect(enrollment.dig('assessments', 'nodes', 0, 'id')).to eq(assessment['id'])
    end
  end

  describe 'In progress tests' do
    it 'should create WIP assessment' do
      response, result = post_graphql(**test_input.merge(in_progress: true)) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        assessment = result.dig('data', 'createAssessment', 'assessment')
        errors = result.dig('data', 'createAssessment', 'errors')
        expect(assessment).to be_present
        expect(assessment['inProgress']).to eq(true)
        expect(assessment['enrollment']).to be_present
        expect(errors).to be_empty
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)
        expect(Hmis::Hud::Assessment.where(enrollment_id: Hmis::Hud::Assessment::WIP_ID).count).to eq(1)
        expect(Hmis::Wip.count).to eq(1)
        expect(Hmis::Wip.first).to have_attributes(enrollment_id: e1.id, client_id: c1.id, project_id: nil)
        expect(Hmis::Hud::Assessment.viewable_by(hmis_user).count).to eq(1)

        # WIP assessment should appear on enrollment query
        response, result = post_graphql(id: e1.id) { get_enrollment_query }
        expect(response.status).to eq 200
        enrollment = result.dig('data', 'enrollment')
        expect(enrollment).to be_present
        expect(enrollment.dig('assessments', 'nodes', 0, 'id')).to eq(assessment['id'])
      end
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
        'should emit error if cannot find form defition',
        ->(input) { input.merge(form_definition_id: '999') },
        {
          'message' => 'Cannot get definition',
          'attribute' => 'formDefinitionId',
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input) { mutation }
        errors = result.dig('data', 'createAssessment', 'errors')
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
