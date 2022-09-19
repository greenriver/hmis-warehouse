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

  let(:test_input) do
    {
      project_name: 'Project 1',
      organization_id: o1.id,
      operating_start_date: Date.today.strftime('%Y-%m-%d'),
      operating_end_date: (Date.today - 1.day).strftime('%Y-%m-%d'),
      description: 'This is a test project',
      contact_information: 'Contact for contact information',
      project_type: Types::HmisSchema::Enums::ProjectType.enum_member_for_value(1).first,
      housing_type: Types::HmisSchema::Enums::HousingType.enum_member_for_value(1).first,
      tracking_method: Types::HmisSchema::Enums::TrackingMethod.enum_member_for_value(0).first,
      target_population: Types::HmisSchema::Enums::TargetPopulation.enum_member_for_value(1).first,
      'HOPWAMedAssistedLivingFac' => Types::HmisSchema::Enums::HOPWAMedAssistedLivingFac.enum_member_for_value(1).first,
      continuum_project: false,
      residential_affiliation: true,
      'HMISParticipatingProject' => true,
    }
  end

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateProject($input: ProjectInput!) {
        createProject(input: { input: $input }) {
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
    mutation_input = test_input
    response, result = post_graphql(input: mutation_input) { mutation }

    expect(response.status).to eq 200
    project = result.dig('data', 'createProject', 'project')
    errors = result.dig('data', 'createProject', 'errors')
    expect(project['id']).to be_present
    expect(errors).to be_empty
  end

  it 'should throw errors if the project is invalid' do
    response, result = post_graphql(input: {}) { mutation }

    project = result.dig('data', 'createProject', 'project')
    errors = result.dig('data', 'createProject', 'errors')

    expect(response.status).to eq 200
    expect(project).to be_nil
    expect(errors).to be_present
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if organization ID is not provided',
        ->(input) { input.except(:organization_id) },
        {
          'fullMessage' => 'Organization must exist',
          'attribute' => 'organization',
        },
        {
          'fullMessage' => 'Organizationid must exist',
          'attribute' => 'organizationId',
        },
      ],
      [
        'should emit error if name is not provided',
        ->(input) { input.except(:project_name) },
        {
          'fullMessage' => 'Projectname must exist',
          'attribute' => 'projectName',
        },
      ],
      [
        'should emit error if name is not provided',
        ->(input) { input.except(:operating_start_date) },
        {
          'fullMessage' => 'Operatingstartdate must exist',
          'attribute' => 'operatingStartDate',
        },
      ],
      [
        'should emit error if project type is not provided and project is not a continuum project',
        ->(input) { input.except(:project_type) },
        {
          'fullMessage' => 'Project type must exist',
          'attribute' => 'projectType',
        },
      ],
      [
        'should not emit error if project type is not provided and project is a continuum project',
        ->(input) { input.except(:project_type).merge(continuum_project: true) },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input: input) { mutation }
        errors = result.dig('data', 'createProject', 'errors')
        expect(response.status).to eq 200
        expect(errors).to contain_exactly(*expected_errors.map { |error_attrs| include(**error_attrs) })
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
