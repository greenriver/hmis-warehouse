###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:all) do
    cleanup_test_environment
  end

  let!(:enrollments) do
    10.times.map do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1
    end
  end

  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_enrollment_details])
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'project households' do
    let(:query) do
      <<~GRAPHQL
        query GetProjectHouseholds($id: ID!, $filters: HouseholdFilterOptions, $sortOrder: HouseholdSortOption, $limit: Int = 10, $offset: Int = 0) {
          project(id: $id) {
            id
            households(
              limit: $limit
              offset: $offset
              sortOrder: $sortOrder
              filters: $filters
            ) {
              offset
              limit
              nodesCount
              nodes {
                ...ProjectEnrollmentsHouseholdFields
                __typename
              }
              __typename
            }
            __typename
          }
        }

        fragment ProjectEnrollmentsHouseholdFields on Household {
          id
          householdSize
          shortId
          householdClients {
            ...ProjectEnrollmentsHouseholdClientFields
            __typename
          }
          __typename
        }

        fragment ProjectEnrollmentsHouseholdClientFields on HouseholdClient {
          id
          relationshipToHoH
          client {
            id
            ...ClientName
            ...ClientIdentificationFields
            __typename
          }
          enrollment {
            id
            entryDate
            exitDate
            inProgress
            __typename
          }
          __typename
        }

        fragment ClientName on Client {
          firstName
          middleName
          lastName
          nameSuffix
          __typename
        }

        fragment ClientIdentificationFields on Client {
          id
          dob
          age
          ssn
          access {
            id
            canViewFullSsn
            canViewPartialSsn
            __typename
          }
          __typename
        }
      GRAPHQL
    end

    let(:variables) do
      {
        "id": p1.id.to_s,
        "limit": 10,
        "offset": 0,
        "filters": {
          "status": [
            'ACTIVE',
            'INCOMPLETE',
          ],
        },
        "sortOrder": 'MOST_RECENT',
      }
    end

    it 'minimizes n+1 queries' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'project', 'households', 'nodes').size).to eq(enrollments.size)
      end.to make_database_queries(count: 20..40)
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'project', 'households', 'nodes').size).to eq(enrollments.size)
      end.to perform_under(300).ms
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
