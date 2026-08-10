###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

# Restriction is resolved per client through the hmis_restricted_client_enrollments view. Every
# client and enrollment policy check consults it, so the paginated list fields must resolve it in
# bulk. These specs assert a constant number of queries against the view: without the preloads it
# grows with the number of records on the page.
RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:all) do
    cleanup_test_environment
  end

  let(:household_count) { 6 }

  # Households of two, where the non-HoH member is a restricted client.
  let!(:households) do
    household_count.times.map do
      hoh_enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, relationship_to_ho_h: 1)
      restricted_client = create(:hmis_hud_client, data_source: ds1, user: u1, restricted: true)
      create(
        :hmis_hud_enrollment,
        data_source: ds1,
        project: p1,
        client: restricted_client,
        household_id: hoh_enrollment.household_id,
        relationship_to_ho_h: 2,
      )
      hoh_enrollment
    end
  end

  # No can_view_restricted_clients, so every restricted client above is hidden from this user.
  let!(:access_control) do
    create_access_control(
      hmis_user,
      p1,
      with_permission: [:can_view_clients, :can_view_client_name, :can_view_project, :can_view_enrollment_details],
    )
  end

  before(:each) { hmis_login(user) }

  # A single N+1 would produce one lookup per enrollment (12 here), so anything in this range means
  # the lookups are batched.
  let(:constant_view_queries) { { matching: /FROM "hmis_restricted_client_enrollments"/, count: 1..4 } }

  describe 'households field' do
    let(:query) do
      <<~GRAPHQL
        query GetProjectHouseholds($id: ID!) {
          project(id: $id) {
            id
            households(limit: 25) {
              nodesCount
              nodes {
                id
                householdSize
                householdClients {
                  id
                  relationshipToHoH
                  client { id firstName }
                  enrollment { id entryDate }
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves restrictions for the whole page in a constant number of queries' do
      expect do
        response, result = post_graphql(id: p1.id.to_s) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'households', 'nodes').size).to eq(household_count)
      end.to make_database_queries(**constant_view_queries)
    end

    it 'omits the restricted household members, but still counts them in householdSize' do
      _, result = post_graphql(id: p1.id.to_s) { query }
      nodes = result.dig('data', 'project', 'households', 'nodes')

      expect(nodes.map { |node| node['householdClients'].size }).to all(eq(1))
      expect(nodes.flat_map { |node| node['householdClients'] }.map { |hc| hc['relationshipToHoH'] }).to all(eq('SELF_HEAD_OF_HOUSEHOLD'))
      expect(nodes.map { |node| node['householdSize'] }).to all(eq(2))
    end
  end

  describe 'single household' do
    # Large enough that a per-member lookup would exceed the expected query count
    let!(:large_household) do
      hoh_enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, relationship_to_ho_h: 1)
      9.times do
        client = create(:hmis_hud_client, data_source: ds1, user: u1, restricted: true)
        create(
          :hmis_hud_enrollment,
          data_source: ds1,
          project: p1,
          client: client,
          household_id: hoh_enrollment.household_id,
          relationship_to_ho_h: 2,
        )
      end
      hoh_enrollment
    end

    let(:query) do
      <<~GRAPHQL
        query GetHousehold($id: ID!) {
          household(id: $id) {
            id
            householdClients {
              id
              client { id firstName }
              enrollment { id }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves restrictions for all members in a constant number of queries' do
      expect do
        response, result = post_graphql(id: large_household.household_id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'household', 'householdClients').size).to eq(1)
      end.to make_database_queries(**constant_view_queries)
    end
  end

  describe 'enrollments field' do
    let(:query) do
      <<~GRAPHQL
        query GetProjectEnrollments($id: ID!) {
          project(id: $id) {
            id
            enrollments(limit: 25) {
              nodesCount
              nodes {
                id
                entryDate
                client { id firstName }
                access { id canEditEnrollments canDeleteEnrollments }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves restrictions for the whole page in a constant number of queries' do
      expect do
        response, result = post_graphql(id: p1.id.to_s) { query }
        expect(response.status).to eq(200), result.inspect
        # Enrollments of hidden clients are excluded by the viewable_by scope
        expect(result.dig('data', 'project', 'enrollments', 'nodes').size).to eq(household_count)
      end.to make_database_queries(**constant_view_queries)
    end
  end

  describe 'client search' do
    let(:query) do
      <<~GRAPHQL
        query SearchClients($input: ClientSearchInput!) {
          clientSearch(input: $input, limit: 25) {
            nodesCount
            nodes {
              id
              firstName
              access { id canEditClient }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves restrictions for the whole page in a constant number of queries' do
      expect do
        response, result = post_graphql(input: { textSearch: 'Bob' }) { query }
        expect(response.status).to eq(200), result.inspect
        # Restricted clients are excluded by the viewable_by scope
        expect(result.dig('data', 'clientSearch', 'nodes').size).to eq(household_count)
      end.to make_database_queries(**constant_view_queries)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
