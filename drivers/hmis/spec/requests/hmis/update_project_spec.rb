require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let!(:ds1) { create :source_data_source, id: 1, hmis: GraphqlHelpers::HMIS_HOSTNAME }
  let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let!(:p1) { create :hmis_hud_project, organization: o1, data_source_id: ds1.id }

  let(:test_input) do
    {
      project_name: 'Project 1',
      operating_start_date: Date.today.strftime('%Y-%m-%d'),
      operating_end_date: (Date.today - 1.day).strftime('%Y-%m-%d'),
      description: 'This is a test project',
      contact_information: 'Contact for contact information',
      project_type: Types::HmisSchema::Enums::ProjectType.enum_member_for_value(2).first,
      housing_type: Types::HmisSchema::Enums::HousingType.enum_member_for_value(3).first,
      tracking_method: Types::HmisSchema::Enums::TrackingMethod.enum_member_for_value(3).first,
      target_population: Types::HmisSchema::Enums::TargetPopulation.enum_member_for_value(4).first,
      'HOPWAMedAssistedLivingFac' => Types::HmisSchema::Enums::HOPWAMedAssistedLivingFac.enum_member_for_value(0).first,
      continuum_project: false,
      residential_affiliation: false,
      'HMISParticipatingProject' => false,
    }
  end

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateProject($id: ID!, $input: ProjectInput!) {
        updateProject(input: { input: $input, id: $id }) {
          project {
            id
            organization {
              id
            }
            projectName
            projectType
            HMISParticipatingProject
            HOPWAMedAssistedLivingFac
            contactInformation
            continuumProject
            description
            housingType
            operatingEndDate
            operatingStartDate
            residentialAffiliation
            targetPopulation
            trackingMethod
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

  it 'should create a project successfully' do
    response, result = post_graphql(id: p1.id, input: test_input) { mutation }

    expect(response.status).to eq 200
    project = result.dig('data', 'updateProject', 'project')
    errors = result.dig('data', 'updateProject', 'errors')
    expect(project).to include(
      'id' => p1.id.to_s,
      'organization' => { 'id' => o1.id.to_s },
      'projectName' => test_input[:project_name],
      'projectType' => test_input[:project_type],
      'HMISParticipatingProject' => test_input['HMISParticipatingProject'],
      'HOPWAMedAssistedLivingFac' => test_input['HOPWAMedAssistedLivingFac'],
      'contactInformation' => test_input[:contact_information],
      'continuumProject' => test_input[:continuum_project],
      'description' => test_input[:description],
      'housingType' => test_input[:housing_type],
      'operatingEndDate' => test_input[:operating_end_date],
      'operatingStartDate' => test_input[:operating_start_date],
      'residentialAffiliation' => test_input[:residential_affiliation],
      'targetPopulation' => test_input[:target_population],
      'trackingMethod' => test_input[:tracking_method],
    )
    expect(errors).to be_empty
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
