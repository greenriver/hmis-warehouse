require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

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

  include_context 'hmis base setup'

  describe 'organization creation tests' do
    let(:u2) do
      user2 = create(:user).tap { |u| u.add_viewable(ds1) }
      hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
      Hmis::Hud::User.from_user(hmis_user2)
    end
    let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u2 }

    let(:mutation) do
      <<~GRAPHQL
        mutation UpdateOrganization($id: ID!, $input: OrganizationInput!) {
          updateOrganization(input: { input: $input, id: $id }) {
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

    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, o1.as_warehouse, hmis_user)
    end

    it 'should update a organization successfully' do
      prev_date_updated = o1.date_updated
      aggregate_failures 'checking response' do
        expect(o1.user_id).to eq(u2.user_id)

        response, result = post_graphql(id: o1.id, input: test_input) { mutation }

        expect(response.status).to eq 200
        organization = result.dig('data', 'updateOrganization', 'organization')
        errors = result.dig('data', 'updateOrganization', 'errors')
        expect(o1.reload.date_updated > prev_date_updated).to eq(true)
        expect(o1.user_id).to eq(u1.user_id)
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

    it 'should throw error if unauthorized' do
      prev_date_updated = o1.date_updated
      remove_permissions(hmis_user, :can_edit_organization)
      aggregate_failures 'checking response' do
        expect(o1.user_id).to eq(u2.user_id)

        response, result = post_graphql(id: o1.id, input: test_input) { mutation }

        expect(response.status).to eq 200
        organization = result.dig('data', 'updateOrganization', 'organization')
        errors = result.dig('data', 'updateOrganization', 'errors')
        expect(organization).to be_nil
        expect(errors).to be_present
        expect(errors).to contain_exactly(include('type' => 'not_allowed'))
        expect(o1.reload.date_updated == prev_date_updated).to eq(true)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
