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
  let(:u2) do
    user2 = create(:user).tap { |u| u.add_viewable(ds1) }
    hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
    Hmis::Hud::User.from_user(hmis_user2)
  end
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, organization: o1, data_source: ds1, user: u2 }
  let(:access_group) { create :edit_access_group }

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
      residential_affiliation: true,
      'HMISParticipatingProject' => false,
    }
  end

  before(:each) do
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    access_group.add_viewable(p1.as_warehouse)
    access_group.add(hmis_user)
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

  it 'should update a project successfully' do
    prev_date_updated = p1.date_updated
    expect(p1.user_id).to eq(u2.user_id)
    response, result = post_graphql(id: p1.id, input: test_input) { mutation }

    expect(response.status).to eq 200
    project = result.dig('data', 'updateProject', 'project')
    errors = result.dig('data', 'updateProject', 'errors')
    expect(p1.reload.date_updated > prev_date_updated).to eq(true)
    expect(p1.user_id).to eq(u1.user_id)
    expect(errors).to be_empty
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
  end

  it 'should allow nulls, and correctly nullify fields' do
    p1.update(description: 'foo', operating_end_date: '2022-01-01', housing_type: 3, continuum_project: 0, residential_affiliation: 1, HMISParticipatingProject: 99)
    input = {
      operating_end_date: nil,
      description: nil,
      housing_type: nil,
      continuum_project: nil,
      residential_affiliation: nil,
      'HMISParticipatingProject' => nil,
    }
    response, result = post_graphql(id: p1.id, input: input) { mutation }

    expect(response.status).to eq 200
    project = result.dig('data', 'updateProject', 'project')
    errors = result.dig('data', 'updateProject', 'errors')
    expect(errors).to be_empty
    expect(project).to include(
      'id' => p1.id.to_s,
      'HMISParticipatingProject' => input['HMISParticipatingProject'],
      'continuumProject' => input[:continuum_project],
      'description' => input[:description],
      'housingType' => input[:housing_type],
      'operatingEndDate' => input[:operating_end_date],
      'residentialAffiliation' => input[:residential_affiliation],
    )

    p1.reload
    expect(p1.operating_end_date).to be_nil
    expect(p1.description).to be_nil
    expect(p1.housing_type).to be_nil
    expect(p1.continuum_project).to eq(99)
    expect(p1.residential_affiliation).to eq(99)
    expect(p1.HMISParticipatingProject).to eq(99)
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
