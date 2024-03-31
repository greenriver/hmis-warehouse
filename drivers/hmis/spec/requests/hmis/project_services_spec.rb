###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  include_context 'hmis service setup'
  let!(:access_control) { create_access_control(hmis_user, p1) }

  describe 'project services query' do
    before(:each) do
      hmis_login(user)
    end

    let(:query) do
      <<~GRAPHQL
        query GetProjectServices($id: ID!, $filters: ServicesForProjectFilterOptions, $sortOrder: ServiceSortOption, $limit: Int = 10, $offset: Int = 0) {
          project(id: $id) {
            id
            services(
              limit: $limit
              offset: $offset
              sortOrder: $sortOrder
              filters: $filters
            ) {
              offset
              limit
              nodesCount
              nodes {
                ...ServiceBasicFields
                enrollment {
                  id
                  entryDate
                  exitDate
                  client {
                    ...ClientNameDobVet
                    __typename
                  }
                  __typename
                }
                __typename
              }
              __typename
            }
            __typename
          }
        }

        fragment ServiceBasicFields on Service {
          id
          dateProvided
          serviceType {
            ...ServiceTypeFields
            __typename
          }
          __typename
        }

        fragment ServiceTypeFields on ServiceType {
          id
          name
          hud
          hudRecordType
          hudTypeProvided
          category
          dateCreated
          dateUpdated
          supportsBulkAssignment
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
      GRAPHQL
    end

    describe 'with more than a page of data' do
      before(:each) do
        # 30 enrollments, each with 10 services (5 HUD, 5 Custom) (300 services total)
        30.times do |index|
          # create WIP or non-WIP Enrollment
          enrollment_factory = index.even? ? :hmis_hud_enrollment : :hmis_hud_wip_enrollment
          en = create(enrollment_factory, data_source: ds1, project: p1)

          # create both HUD and Custom services
          5.times { create(:hmis_hud_service, date_provided: Date.yesterday, data_source: ds1, enrollment: en, client: en.client) }
          5.times { create(:hmis_custom_service, date_provided: Date.yesterday, data_source: ds1, enrollment: en, client: en.client) }
        end
      end
      let(:limit) { 50 } # resolve a page of 50 services

      it 'to avoid N+1 queries' do
        expect do
          response, result = post_graphql(id: p1.id, limit: limit) { query }
          aggregate_failures 'checking response' do
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'project', 'services', 'nodesCount')).to eq(30 * 10)
            expect(result.dig('data', 'project', 'services', 'nodes').count).to eq(limit)
          end
        end.to make_database_queries(count: 10..30)
      end

      it 'to execute in a reasonable amount of time' do
        expect do
          response, result = post_graphql(id: p1.id, limit: limit) { query }
          expect(response.status).to eq(200), result.inspect
        end.to perform_under(300).ms
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
