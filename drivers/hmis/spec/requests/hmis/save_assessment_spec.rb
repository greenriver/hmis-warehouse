require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2023-01-01' }
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
      values: { 'linkid-date' => '2023-03-01' },
      hud_values: { 'informationDate' => '2023-03-01' },
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation SaveAssessment($input: SaveAssessmentInput!) {
        saveAssessment(input: $input) {
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
            customForm {
              #{scalar_fields(Types::HmisSchema::CustomForm)}
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
    response, result = post_graphql(input: { input: test_input }) { mutation }
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      expect(errors).to be_empty
      expect(assessment).to be_present
      expect(assessment['enrollment']).to be_present
      expect(assessment).to include(
        'inProgress' => true,
        'assessmentDate' => '2023-03-01',
        'customForm' => include('values' => test_input[:values]),
      )
      expect(Hmis::Hud::CustomAssessment.count).to eq(1)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(1)
      expect(Hmis::Hud::CustomAssessment.where(enrollment_id: Hmis::Hud::CustomAssessment::WIP_ID).count).to eq(1)
      expect(Hmis::Wip.count).to eq(1)
      expect(Hmis::Wip.first).to have_attributes(enrollment_id: e1.id, client_id: c1.id, project_id: nil)
      expect(Hmis::Hud::CustomAssessment.viewable_by(hmis_user).count).to eq(1)
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
    response, result = post_graphql(input: { input: test_input }) { mutation }
    assessment_id = result.dig('data', 'saveAssessment', 'assessment', 'id')
    errors = result.dig('data', 'saveAssessment', 'errors')
    expect(errors).to be_empty
    expect(assessment_id).to be_present
    expect(Hmis::Hud::CustomAssessment.count).to eq(1)
    expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(1)

    # Subsequent request should update the existing WIP assessment
    new_information_date = '2024-01-01'
    input = {
      assessment_id: assessment_id,
      values: { 'linkid-date' => new_information_date },
      hud_values: { 'informationDate' => new_information_date },
    }

    response, result = post_graphql(input: { input: input }) { mutation }
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      expect(errors).to be_empty
      expect(assessment).to be_present
      expect(assessment['enrollment']).to be_present
      expect(assessment).to include(
        'inProgress' => true,
        'assessmentDate' => new_information_date,
        'customForm' => include('values' => input[:values]),
      )
      expect(Hmis::Hud::CustomAssessment.count).to eq(1)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(1)
      expect(Hmis::Wip.count).to eq(1)
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if enrollment doesn\'t exist',
        ->(input) { input.merge(enrollment_id: '999') },
        {
          'fullMessage' => 'Enrollment must exist',
        },
      ],
      [
        'should emit error if cannot find form definition',
        ->(input) { input.merge(form_definition_id: '999') },
        {
          'fullMessage' => 'Form definition must exist',
        },
      ],
      [
        'should emit error if cannot find assessment',
        ->(input) { input.merge(assessment_id: '999') },
        {
          'fullMessage' => 'Assessment must exist',
        },
      ],
      [
        'should emit error if neithor enrollment nor assessment are provided',
        ->(input) { input.except(:enrollment_id, :assessment_id) },
        {
          'fullMessage' => 'Enrollment must exist',
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input: { input: input }) { mutation }
        errors = result.dig('data', 'saveAssessment', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(errors).to match(expected_errors.map { |h| a_hash_including(**h) })
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
