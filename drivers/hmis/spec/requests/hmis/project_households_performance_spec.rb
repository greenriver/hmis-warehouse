###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  let!(:enrollments) do
    10.times.map do
      hoh_enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1)
      create(:hmis_hud_enrollment, data_source: ds1, project: p1, household_id: hoh_enrollment.household_id)

      # add some services and staff assignments to test n+1 for optional columns
      3.times { create :hmis_hud_service, data_source: ds1, project: p1, enrollment: hoh_enrollment, user: u1 }
      3.times { create :hmis_custom_service, data_source: ds1, project: p1, enrollment: hoh_enrollment, user: u1 }
      3.times { create :hmis_staff_assignment, data_source: ds1, enrollment: hoh_enrollment }

      hoh_enrollment
    end
  end

  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'project households' do
    # Tests the query fetched from the HMIS frontend Project Households table.
    # This should be updated periodically to ensure it reflects the current query. The below query and variables are copied from browser dev tools network tab.
    let(:query) do
      <<~GRAPHQL
          query GetProjectHouseholds($id: ID!, $filters: HouseholdFilterOptions, $sortOrder: HouseholdSortOption, $limit: Int = 10, $offset: Int = 0, $includeStaffAssignment: Boolean = false, $includeMoveInDate: Boolean = false, $includeLastContact: Boolean = false) {
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
          ...HouseholdWithStaffAssignments @include(if: $includeStaffAssignment)
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
            lockVersion
            entryDate
            exitDate
            inProgress
            autoExited
            moveInDate @include(if: $includeMoveInDate)
            lastContact @include(if: $includeLastContact) {
              contactDate
              contactType
              __typename
            }
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

        fragment HouseholdWithStaffAssignments on Household {
          id
          currentStaffAssignments {
            ...StaffAssignmentDetails
            __typename
          }
          __typename
        }

        fragment StaffAssignmentDetails on StaffAssignment {
          id
          user {
            id
            name
            __typename
          }
          staffAssignmentRelationship
          assignedAt
          unassignedAt
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
        "includeStaffAssignment": false,
        "includeMoveInDate": false,
        "includeLastContact": false,
      }
    end

    it 'minimizes n+1 queries' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'project', 'households', 'nodes').size).to eq(enrollments.size), result.inspect
      end.to make_database_queries(count: 10..30)
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'project', 'households', 'nodes').size).to eq(enrollments.size), result.inspect
      end.to perform_under(300).ms
    end

    describe 'with filters' do
      let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
      let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
      let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, user: u1, household_id: '1' }
      let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c2, user: u1, household_id: '1' }
      let!(:e3) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p2, client: c2, user: u1, household_id: '1' }

      it 'should only return a household once if there are both WIP and completed members' do
        _, result = post_graphql({ id: p2.id.to_s, filters: { status: ['ACTIVE', 'INCOMPLETE'] } }) { query }
        expect(Hmis::Hud::Household.where(household_id: '1').count).to eq(1)
        expect(result.dig('data', 'project', 'households', 'nodes').count).to eq(1), result.inspect
      end
    end

    describe 'with optional columns' do
      let(:variables) do
        {
          "id": p1.id.to_s,
          "limit": 10,
          "offset": 0,
          "filters": {},
          "sortOrder": 'MOST_RECENT',
          "includeStaffAssignment": true,
          "includeMoveInDate": true,
          "includeLastContact": true,
        }
      end

      it 'minimizes n+1 queries' do
        expect do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'households', 'nodes').size).to eq(enrollments.size), result.inspect
        end.to make_database_queries(count: 25..35) # TODO - this fails, but should pass once the rails 7.1 PR is merged in which removes the resets in Sources::ActiveRecordAssociation
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
