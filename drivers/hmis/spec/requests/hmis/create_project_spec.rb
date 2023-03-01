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

  let(:test_input) do
    {
      project_name: 'Project 1',
      organization_id: o1.id,
      operating_start_date: 1.year.ago.strftime('%Y-%m-%d'),
      operating_end_date: 1.week.ago.strftime('%Y-%m-%d'),
      description: 'This is a test project',
      contact_information: 'Contact for contact information',
      project_type: Types::HmisSchema::Enums::ProjectType.enum_member_for_value(1).first,
      housing_type: Types::HmisSchema::Enums::Hud::HousingType.enum_member_for_value(1).first,
      tracking_method: Types::HmisSchema::Enums::Hud::TrackingMethod.enum_member_for_value(0).first,
      target_population: Types::HmisSchema::Enums::Hud::TargetPopulation.enum_member_for_value(1).first,
      'HOPWAMedAssistedLivingFac' => Types::HmisSchema::Enums::Hud::HOPWAMedAssistedLivingFac.enum_member_for_value(1).first,
      continuum_project: false,
      residential_affiliation: true,
      'HMISParticipatingProject' => nil,
    }
  end

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, o1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateProject($input: ProjectInput!) {
        createProject(input: { input: $input }) {
          project {
            #{scalar_fields(Types::HmisSchema::Project)}
            organization {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should create a project successfully' do
    mutation_input = test_input
    response, result = post_graphql(input: mutation_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      project = result.dig('data', 'createProject', 'project')
      errors = result.dig('data', 'createProject', 'errors')
      expect(project['id']).to be_present
      expect(project['active']).to eq(false)
      expect(errors).to be_empty
    end
  end

  it 'should throw errors if the project is invalid' do
    response, result = post_graphql(input: {}) { mutation }

    project = result.dig('data', 'createProject', 'project')
    errors = result.dig('data', 'createProject', 'errors')

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      expect(project).to be_nil
      expect(errors).to be_present
    end
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
          'fullMessage' => 'Organization must exist',
          'attribute' => 'organizationId',
        },
      ],
      [
        'should emit error if name is not provided',
        ->(input) { input.except(:project_name) },
        {
          'fullMessage' => 'Project name must exist',
          'attribute' => 'projectName',
        },
      ],
      [
        'should emit error if start date is not provided',
        ->(input) { input.except(:operating_start_date) },
        {
          'fullMessage' => 'Operating start date must exist',
          'attribute' => 'operatingStartDate',
        },
      ],
      [
        'should emit error if end date is after start date',
        ->(input) { { **input, operating_end_date: 2.years.ago.strftime('%Y-%m-%d') } },
        {
          'message' => 'must be on or after start date',
          'attribute' => 'operatingEndDate',
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
        'should emit error if project type is not valid',
        ->(input) { { **input, project_type: 'INVALID' } },
        {
          'fullMessage' => 'Project type is invalid',
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
