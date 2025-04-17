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
      other_enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, household_id: hoh_enrollment.household_id)

      # add some services and staff assignments to test n+1 for optional columns
      3.times { create :hmis_hud_service, data_source: ds1, project: p1, enrollment: hoh_enrollment, user: u1 }
      3.times { create :hmis_custom_service, data_source: ds1, project: p1, enrollment: hoh_enrollment, user: u1 }
      3.times { create :hmis_staff_assignment, data_source: ds1, enrollment: hoh_enrollment }

      [hoh_enrollment, other_enrollment]
    end.flatten
  end

  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'project enrollments' do
    # Tests the query fetched from the HMIS frontend Project Enrollments table.
    # This should be updated periodically to ensure it reflects the current query. The below query and variables are copied from browser dev tools network tab.
    let(:query) do
      <<~GRAPHQL
        query GetProjectEnrollments($id: ID!, $filters: EnrollmentsForProjectFilterOptions, $sortOrder: EnrollmentSortOption, $limit: Int = 10, $offset: Int = 0, $includeStaffAssignment: Boolean = false, $includeMoveInDate: Boolean = false, $includeLastContact: Boolean = false) {
          project(id: $id) {
            id
            enrollments(
              limit: $limit
              offset: $offset
              sortOrder: $sortOrder
              filters: $filters
            ) {
              offset
              limit
              nodesCount
              nodes {
                ...ProjectEnrollmentQueryEnrollmentFields
                __typename
              }
              __typename
            }
            __typename
          }
        }

        fragment ProjectEnrollmentQueryEnrollmentFields on Enrollment {
          ...ProjectEnrollmentFields
          ...EnrollmentWithOptionalFields
          __typename
        }

        fragment ProjectEnrollmentFields on Enrollment {
          id
          lockVersion
          entryDate
          exitDate
          autoExited
          inProgress
          relationshipToHoH
          enrollmentCoc
          householdId
          householdShortId
          householdSize
          client {
            id
            ...ClientNameDobVet
            ...ClientIdentificationFields
            __typename
          }
          __typename
        }

        fragment ClientNameDobVet on Client {
          ...ClientName
          dob
          veteranStatus
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

        fragment EnrollmentWithOptionalFields on Enrollment {
          moveInDate @include(if: $includeMoveInDate)
          lastContact @include(if: $includeLastContact) {
            contactDate
            contactType
            __typename
          }
          staffAssignments @include(if: $includeStaffAssignment) {
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
        "limit": 25,
        "offset": 0,
        "includeStaffAssignment": false,
        "includeMoveInDate": false,
        "includeLastContact": false,
        "filters": {},
        "sortOrder": 'MOST_RECENT',
      }
    end

    it 'minimizes n+1 queries' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'project', 'enrollments', 'nodes').size).to eq(enrollments.size), result.inspect
      end.to make_database_queries(count: 10..30)
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'project', 'enrollments', 'nodes').size).to eq(enrollments.size), result.inspect
      end.to perform_under(300).ms
    end

    describe 'with optional columns' do
      it 'minimizes n+1 queries' do
        adjusted_variables = variables.merge({
                                               "includeStaffAssignment": true,
                                               "includeMoveInDate": true,
                                               "includeLastContact": true,
                                             })

        expect do
          _, result = post_graphql(**adjusted_variables) { query }
          expect(result.dig('data', 'project', 'enrollments', 'nodes').size).to eq(enrollments.size), result.inspect
        end.to make_database_queries(count: 10..55) # Query count is high due to optional fields, especially "last contact date". Can maybe optimize further
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
