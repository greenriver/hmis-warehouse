require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let(:ds1) { create :hmis_data_source }
  let(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let(:p1) { create :hmis_hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })

    @hmis_user = Hmis::User.find(user.id)
    @hmis_user.hmis_data_source_id = ds1.id
  end

  let(:test_input) do
    {
      enrollment_id: e1.id.to_s,
      assessment_role: 'INTAKE',
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateAssessment($enrollmentId: ID!, $assessmentRole: String!) {
        createAssessment(input: { enrollmentId: $enrollmentId, assessmentRole: $assessmentRole }) {
          assessment {
            id
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
    response, result = post_graphql(test_input) { mutation }

    expect(response.status).to eq 200
    assessment = result.dig('data', 'createAssessment', 'assessment')
    errors = result.dig('data', 'createAssessment', 'errors')
    expect(assessment['id']).to be_present
    expect(errors).to be_empty
  end

  # it 'should throw errors if the organization is invalid' do
  #   response, result = post_graphql(input: {}) { mutation }

  #   organization = result.dig('data', 'createOrganization', 'organization')
  #   errors = result.dig('data', 'createOrganization', 'errors')

  #   expect(response.status).to eq 200
  #   expect(organization).to be_nil
  #   expect(errors).to be_present
  # end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
