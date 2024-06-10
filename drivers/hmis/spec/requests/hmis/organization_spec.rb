#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

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

  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Strawberries' }
  let!(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Raspberries' }
  let!(:o3) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Blueberries' }
  let!(:o4) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Cherries' }

  describe 'organization query' do
    before(:each) do
      create_access_control(hmis_user, ds1)
      hmis_login(user)
    end

    let(:query) do
      <<~GRAPHQL
        query GetOrganizations($filters: OrganizationFilterOptions) {
          organizations(filters: $filters) {
            nodesCount
            nodes {
              id
              hudId
              organizationName
              projects(limit: 1) {
                nodesCount
              }
            }
          }
        }
      GRAPHQL
    end

    it 'returns all organizations when no filters are passed' do
      response, result = post_graphql { query }
      expect(response.status).to eq 200
      orgs = result.dig('data', 'organizations', 'nodes')
      expect(orgs.length).to eq(4)
    end

    it 'returns only matching organizations when name filter is passed' do
      response, result = post_graphql(filters: { search_term: 'berries' }) { query }
      expect(response.status).to eq 200
      orgs = result.dig('data', 'organizations', 'nodes')
      expect(orgs.length).to eq(3)
      expect(orgs.pluck('organizationName')).not_to include('Cherries')
    end

    it 'returns correctly when an ID is passed' do
      response, result = post_graphql(filters: { search_term: o1.id.to_s }) { query }
      expect(response.status).to eq 200
      orgs = result.dig('data', 'organizations', 'nodes')
      expect(orgs.length).to eq(1)
      expect(orgs.first['organizationName']).to eq(o1.organization_name)
    end

    it 'does not error when a large integer is passed' do
      response, result = post_graphql(filters: { search_term: '73892738928' }) { query }
      expect(response.status).to eq 200
      orgs = result.dig('data', 'organizations', 'nodes')
      expect(orgs.length).to eq(0)
    end
  end
end
