require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:test_input) do
    {
      organization_name: 'Organization 1',
      victim_service_provider: true,
      description: 'A sample organization',
      contact_information: 'Contact for contact information',
    }
  end

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'organization creation tests' do
    let(:user) { create :user }
    let!(:ds1) { create :source_data_source, id: 1, hmis: GraphqlHelpers::HMIS_HOSTNAME }
    before(:each) do
      user.add_viewable(ds1)
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateOrganization($input: OrganizationInput!) {
          createOrganization(input: { input: $input }) {
            organization {
              id
              organizationName
              projects {
                id
              }
              victimServiceProvider
              description
              contactInformation
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

    it 'should create a organization successfully' do
      mutation_input = test_input
      response, result = post_graphql(input: mutation_input) { mutation }

      expect(response.status).to eq 200
      organization = result.dig('data', 'createOrganization', 'organization')
      errors = result.dig('data', 'createOrganization', 'errors')
      expect(organization['id']).to be_present
      expect(errors).to be_empty
    end

    it 'should throw errors if the organization is invalid' do
      response, result = post_graphql(input: {}) { mutation }

      organization = result.dig('data', 'createOrganization', 'organization')
      errors = result.dig('data', 'createOrganization', 'errors')

      expect(response.status).to eq 200
      expect(organization).to be_nil
      expect(errors).to be_present
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
