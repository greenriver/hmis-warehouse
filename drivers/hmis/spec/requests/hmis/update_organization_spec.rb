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
    let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
    before(:each) do
      user.add_viewable(ds1)
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation UpdateOrganization($id: ID!, $input: OrganizationInput!) {
          updateOrganization(input: { input: $input, id: $id }) {
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

    it 'should update a organization successfully' do
      response, result = post_graphql(id: o1.id, input: test_input) { mutation }

      expect(response.status).to eq 200
      organization = result.dig('data', 'updateOrganization', 'organization')
      errors = result.dig('data', 'updateOrganization', 'errors')
      expect(organization).to include(
        'id' => o1.id.to_s,
        'organizationName' => test_input[:organization_name],
        'victimServiceProvider' => test_input[:victim_service_provider],
        'description' => test_input[:description],
        'contactInformation' => test_input[:contact_information],
      )
      expect(errors).to be_empty
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
