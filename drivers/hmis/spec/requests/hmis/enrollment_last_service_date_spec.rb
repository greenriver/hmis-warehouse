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
  include_context 'hmis service setup'

  before(:each) do
    hmis_login(user)
  end

  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let(:query) do
    <<~GRAPHQL
      query EnrollmentsWithLastServiceDate(
        $clientId: ID!
        $serviceTypeId: ID!
      ) {
        client(id: $clientId) {
          enrollments {
            nodes {
              id
              lastServiceDate(serviceTypeId: $serviceTypeId)
              lastBedNightDate
            }
          }
        }
      }
    GRAPHQL
  end

  let!(:access_conrtol) { create_access_control(hmis_user, p1) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 1.year.ago }
  let!(:s1_hud) { create(:hmis_hud_service_bednight, date_provided: 8.months.ago, data_source: ds1, client: c1, enrollment: e1) }
  let!(:s2_hud) { create(:hmis_hud_service_bednight, date_provided: 4.months.ago, data_source: ds1, client: c1, enrollment: e1) }
  let!(:s3_hud) { create(:hmis_hud_service_path, date_provided: 6.months.ago, data_source: ds1, client: c1, enrollment: e1) }
  let!(:s4_hud) { create(:hmis_hud_service_path, date_provided: 2.months.ago, data_source: ds1, client: c1, enrollment: e1) }

  let!(:s5_custom) { create(:hmis_custom_service, date_provided: 1.months.ago, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1) }
  let!(:s6_custom) { create(:hmis_custom_service, date_provided: 3.month.ago, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1) }
  let!(:s7_custom) { create(:hmis_custom_service, date_provided: 1.week.ago, data_source: ds1, client: c1, enrollment: e1) }

  let(:bed_night_cst) { Hmis::Hud::CustomServiceType.find_by(hud_record_type: 200) }

  describe 'resolving lastServiceDate' do
    it 'works when asking for most recent Bed Night date (HUD service type)' do
      _, result = post_graphql(client_id: c1.id, serviceTypeId: bed_night_cst.id) { query }
      enrollments = result.dig('data', 'client', 'enrollments', 'nodes').map(&:deep_symbolize_keys)

      expected_date = s2_hud.date_provided.strftime('%Y-%m-%d')
      expect(enrollments).to contain_exactly(
        a_hash_including(id: e1.id.to_s, lastServiceDate: expected_date, lastBedNightDate: expected_date),
      )
    end

    it 'works when asking for most recent service date for a Custom Service Type' do
      _, result = post_graphql(client_id: c1.id, serviceTypeId: cst1.id) { query }
      enrollments = result.dig('data', 'client', 'enrollments', 'nodes').map(&:deep_symbolize_keys)

      # s5_custom is the most recent custom service with type cst1
      expect(enrollments).to contain_exactly(
        a_hash_including(id: e1.id.to_s, lastServiceDate: s5_custom.date_provided.strftime('%Y-%m-%d')),
      )
    end

    it 'minimizes N+1' do
      30.times do
        create(:hmis_hud_service_bednight, data_source: ds1, client: c1, enrollment: e1)
      end

      expect do
        _, result = post_graphql(client_id: c1.id, serviceTypeId: bed_night_cst.id) { query }
        enrollments = result.dig('data', 'client', 'enrollments', 'nodes').map(&:deep_symbolize_keys)
        expect(enrollments.map { |e| e[:lastServiceDate] }.compact.size).to eq(enrollments.size)
      end.to make_database_queries(count: 10..30)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
