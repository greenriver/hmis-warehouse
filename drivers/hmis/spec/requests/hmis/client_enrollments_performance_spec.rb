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

  let!(:client) do
    create :hmis_hud_client_complete, data_source: ds1, user: u1
  end
  let!(:enrollments) do
    enrollments = []
    5.times.each do
      project = create :hmis_hud_project, data_source: ds1, organization: o1, user: u1
      enrollments << create(:hmis_hud_enrollment, data_source: ds1, project: project, client: client, user: u1)
      enrollments << create(:hmis_hud_wip_enrollment, data_source: ds1, project: project, client: client, user: u1)
    end
    enrollments
  end
  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_enrollment_details, :can_view_project])
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'client enrollments' do
    let(:query) do
      <<~GRAPHQL
        query GetClientEnrollments($id: ID!, $limit: Int = 10, $offset: Int = 0, $filters: EnrollmentsForClientFilterOptions) {
          client(id: $id) {
            id
            enrollments(
              limit: $limit
              offset: $offset
              sortOrder: MOST_RECENT
              filters: $filters
            ) {
              offset
              limit
              nodesCount
              nodes {
                ...ClientEnrollmentFields
                __typename
              }
              __typename
            }
            __typename
          }
        }

        fragment ClientEnrollmentFields on Enrollment {
          id
          lockVersion
          entryDate
          exitDate
          moveInDate
          lastBedNightDate
          projectName
          organizationName
          projectType
          inProgress
          relationshipToHoH
          access {
            id
            canViewEnrollmentDetails
            __typename
          }
          __typename
        }
      GRAPHQL
    end

    let(:variables) do
      {
        "limit": 10,
        "offset": 0,
        "id": client.id,
      }
    end

    it 'minimizes n+1 queries' do
      expect do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'client', 'enrollments', 'nodes').size).to eq(enrollments.size)
      end.to make_database_queries(count: 10..40)
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'client', 'enrollments', 'nodes').size).to eq(enrollments.size)
      end.to perform_under(250).ms
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
