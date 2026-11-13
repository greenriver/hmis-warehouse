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

  before(:all) do
    cleanup_test_environment
  end

  let(:search_term) { 'ross' }

  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_enrollment_details, :can_view_project])
  end

  before(:each) do
    hmis_login(user)
  end

  # Setup: N clients that each have N enrollments at N different projects.
  # (Do this to test performance of authorization check, which is based on user access to projects the client has enrollments at)
  let(:n) { 10 }
  let!(:projects) do
    create_list(:hmis_hud_project, n, data_source: ds1, organization: o1, user: u1)
  end
  let!(:clients) do
    create_list(:hmis_hud_client_complete, n, data_source: ds1, user: u1, LastName: search_term)
  end
  let!(:enrollments) do
    clients.map do |client|
      projects.map do |project|
        create(:hmis_hud_enrollment, data_source: ds1, project: project, client: client, user: u1)
      end
    end.flatten
  end

  describe 'client search' do
    # Reflects the search query used in the frontend, see src/api/operations/client.queries.graphql
    let(:query) do
      <<~GRAPHQL
        query SearchClients($filters: ClientFilterOptions, $input: ClientSearchInput!, $limit: Int, $offset: Int, $sortOrder: ClientSortOption = LAST_NAME_A_TO_Z, $includeSsn: Boolean = false) {
          clientSearch(
            input: $input
            filters: $filters
            limit: $limit
            offset: $offset
            sortOrder: $sortOrder
          ) {
            offset
            limit
            nodesCount
            nodes {
              ...ClientSearchResultFields
              __typename
            }
            searchQueryId
            __typename
          }
        }

        fragment ClientSearchResultFields on Client {
          ...ClientName
          ...ClientIdentificationFields
          ...ClientSsnFields @include(if: $includeSsn)
          dateCreated
          dateDeleted
          dateUpdated
          externalIds {
            ...ClientIdentifierFields
            __typename
          }
          alerts {
            ...ClientAlertFields
            __typename
          }
          __typename
        }

        fragment ClientName on Client {
          id
          lockVersion
          firstName
          middleName
          lastName
          nameSuffix
          __typename
        }

        fragment ClientIdentificationFields on Client {
          id
          lockVersion
          dob
          age
          gender
          pronouns
          __typename
        }

        fragment ClientSsnFields on Client {
          id
          lockVersion
          ssn
          access {
            id
            canViewFullSsn
            canViewPartialSsn
            __typename
          }
          __typename
        }

        fragment ClientIdentifierFields on ExternalIdentifier {
          id
          identifier
          url
          label
          type
          __typename
        }

        fragment ClientAlertFields on ClientAlert {
          id
          note
          expirationDate
          createdBy {
            ...UserFields
            __typename
          }
          createdAt
          priority
          __typename
        }

        fragment UserFields on ApplicationUser {
          __typename
          id
          name
          firstName
          lastName
          email
        }
      GRAPHQL
    end

    let(:variables) do
      {
        sortOrder: 'BEST_MATCH',
        includeSsn: true,
        input: {
          textSearch: search_term,
        },
        offset: 0,
        limit: 25,
      }
    end

    it 'minimizes n+1 queries' do
      # TODO(#185555687): improve performance of client search, decrease the upper bound here
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'clientSearch', 'nodes').size).to eq(n)
      end.to make_database_queries(count: 10..35)
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'clientSearch', 'nodes').size).to eq(n)
      end.to perform_under(300).ms
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
