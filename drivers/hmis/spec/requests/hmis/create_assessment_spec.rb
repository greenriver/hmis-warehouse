require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let(:p1) { create :hmis_hud_project, data_source: ds1, OrganizationID: o1.OrganizationID, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
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
      mutation CreateAssessment($enrollmentId: ID!, $formDefinitionId: ID!, $values: JsonObject!, $assessmentDate: String) {
        createAssessment(input: {
          enrollmentId: $enrollmentId,
          formDefinitionId: $formDefinitionId,
          assessmentDate: $assessmentDate,
          values: $values,
        }) {
          assessment {
            id
            enrollment {
              id
            }
            user {
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
                definition
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

  it 'should create an assessment successfully' do
    response, result = post_graphql(**test_input) { mutation }

    expect(response.status).to eq 200
    assessment = result.dig('data', 'createAssessment', 'assessment')
    errors = result.dig('data', 'createAssessment', 'errors')
    expect(assessment['id']).to be_present
    expect(errors).to be_empty
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
        expect(response.status).to eq 200
        expect(errors).to contain_exactly(*expected_errors.map { |error_attrs| include(**error_attrs) })
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
