###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Strawberries' }
  let!(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Raspberries' }
  let!(:o3) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Blueberries' }
  let!(:o4) { create :hmis_hud_organization, data_source: ds1, user: u1, OrganizationName: 'Cherries' }

  before(:each) { hmis_login(user) }

  describe 'organization query' do
    let!(:access_control) { create_access_control(hmis_user, ds1) }

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

    context 'when there are multiple HMIS data sources' do
      let!(:ds2) { create :hmis_data_source }
      let!(:o5) { create :hmis_hud_organization, data_source: ds2, OrganizationName: 'Pineapples' }
      let!(:ds2_access_control) { create_access_control(hmis_user, ds2) }

      it 'does not return organizations from other data source' do
        response, result = post_graphql { query }
        expect(response.status).to eq 200
        organizations = result.dig('data', 'organizations', 'nodes')
        expect(organizations.size).to eq(4)
        expect(organizations).to contain_exactly(
          match(a_hash_including({ 'organizationName': o1.organization_name }.stringify_keys)),
          match(a_hash_including({ 'organizationName': o2.organization_name }.stringify_keys)),
          match(a_hash_including({ 'organizationName': o3.organization_name }.stringify_keys)),
          match(a_hash_including({ 'organizationName': o4.organization_name }.stringify_keys)),
        )
      end
    end
  end

  describe 'organization access' do
    let(:access_query) do
      <<~GRAPHQL
        query OrganizationAccess($id: ID!) {
          organization(id: $id) {
            id
            access {
              id
              canEditOrganization
              canDeleteOrganization
            }
          }
        }
      GRAPHQL
    end

    def expect_organization_access!(organization:, can_edit:, can_delete:)
      response, result = post_graphql(id: organization.id.to_s) { access_query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'organization', 'access')).to include(
        'id' => organization.id.to_s,
        'canEditOrganization' => can_edit,
        'canDeleteOrganization' => can_delete,
      )
    end

    context 'with full permissions via data source access' do
      let!(:access_control) { create_access_control(hmis_user, ds1) }

      it 'returns true for edit and delete' do
        expect_organization_access!(organization: o1, can_edit: true, can_delete: true)
      end
    end

    context 'with view and edit but not delete' do
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_edit_organization]) }

      it 'returns true for edit and false for delete' do
        expect_organization_access!(organization: o1, can_edit: true, can_delete: false)
      end
    end

    context 'with view-only on this data source' do
      # cruft: even if the user has full edit permissions in a different data source
      let!(:other_data_source) { create :hmis_data_source }
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project]) }
      let!(:full_access_other_data_source) { create_access_control(hmis_user, other_data_source) }

      it 'returns false for edit and delete' do
        expect_organization_access!(organization: o1, can_edit: false, can_delete: false)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
