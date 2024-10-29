###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'BulkAssignService', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  # Testing the query that is used by the HMIS Bulk Services "find by last bed night" and "search clients" tables
  subject(:query) do
    <<~GRAPHQL
      query BulkServicesClientSearch($textSearch: String!, $filters: ClientFilterOptions, $limit: Int, $offset: Int, $sortOrder: ClientSortOption, $serviceTypeId: ID!, $projectId: ID!, $serviceDate: ISO8601Date!) {

        clientSearch(
          input: {textSearch: $textSearch}
          filters: $filters
          limit: $limit
          offset: $offset
          sortOrder: $sortOrder
        ) {
          offset
          limit
          nodesCount
          nodes {
            id
            ...ClientName
            ...ClientIdentificationFields
            alerts {
              ...ClientAlertFields
              __typename
            }
            activeEnrollment(projectId: $projectId, openOnDate: $serviceDate) {
              id
              entryDate
              lastServiceDate(serviceTypeId: $serviceTypeId)
              services(
                limit: 25
                offset: 0
                filters: {dateProvided: $serviceDate, serviceType: [$serviceTypeId]}
              ) {
                limit
                offset
                nodesCount
                nodes {
                  id
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
        ssn
        gender
        access {
          id
          canViewFullSsn
          canViewPartialSsn
          __typename
        }
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

  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let(:bednight_service_type) { Hmis::Hud::CustomServiceType.find_by(hud_record_type: 200) }
  let(:today) { Date.current }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.month.ago }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.month.ago }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.month.ago }
  let!(:e3_bednight1) { create :hmis_hud_service, date_provided: today, data_source: ds1, enrollment: e3, client: e3.client, record_type: 200, type_provided: 200 }
  let!(:e3_bednight2) { create :hmis_hud_service, date_provided: 1.week.ago, data_source: ds1, enrollment: e3, client: e3.client, record_type: 200, type_provided: 200 }

  def perform_query(service_date:, text_search: '', filters: {})
    input = {
      text_search: text_search,
      filters: filters,
      limit: 25,
      offset: 0,
      sort_order: :BEST_MATCH,
      service_type_id: bednight_service_type.id,
      project_id: p1.id,
      service_date: service_date,
    }

    response, result = post_graphql(input) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'clientSearch', 'nodes')
  end

  before(:each) do
    hmis_login(user)
  end

  it 'can query by search term (client id)' do
    res = perform_query(service_date: e3_bednight2.date_provided, text_search: e3.client.id.to_s)
    expect(res).to contain_exactly(
      include('id' => e3.client.id.to_s),
    )

    expect(res.first['activeEnrollment']).to include(
      'id' => e3.id.to_s,
      # most recent service date was e3_bednight1
      'lastServiceDate' => e3_bednight1.date_provided.strftime('%Y-%m-%d'),
      # service on requested service_date was e3_bednight2
      'services' => include(
        'nodesCount' => 1,
        'nodes' => contain_exactly(a_hash_including('id' => '1' + e3_bednight2.id.to_s)), # 1 prefix is from hmis_services view
      ),
    )
  end

  it 'can query by last bed night date' do
    service_filter = {
      start_date: today - 1.month,
      end_date: today,
      service_type: bednight_service_type.id,
      project_id: p1.id,
    }
    res = perform_query(service_date: today, filters: { service_in_range: service_filter })
    expect(res).to contain_exactly(
      # only e3 had a service on the specified date (today)
      include('id' => e3.client.id.to_s),
    )
  end
end
