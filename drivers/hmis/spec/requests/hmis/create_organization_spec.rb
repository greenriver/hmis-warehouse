require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:test_input) do
    {
      organization_name: 'Organization 1',
      victim_service_provider: nil,
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
    let!(:ds1) { create :hmis_data_source }
    let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
    before(:each) do
      hmis_login(user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateOrganization($input: OrganizationInput!) {
          createOrganization(input: { input: $input }) {
            organization {
              id
              organizationName
              projects {
                nodes {
                  id
                }
              }
              victimServiceProvider
              description
              contactInformation
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    it 'should create a organization successfully' do
      mutation_input = test_input
      response, result = post_graphql(input: mutation_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        organization = result.dig('data', 'createOrganization', 'organization')
        errors = result.dig('data', 'createOrganization', 'errors')
        expect(organization['id']).to be_present
        expect(errors).to be_empty
      end
    end

    it 'should throw errors if the organization is invalid' do
      response, result = post_graphql(input: {}) { mutation }

      organization = result.dig('data', 'createOrganization', 'organization')
      errors = result.dig('data', 'createOrganization', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(organization).to be_nil
        expect(errors).to be_present
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
