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

  before(:each) do
    hmis_login(user)
  end

  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let(:query) do
    <<~GRAPHQL
      query ClientSearchWithActiveEnrollment(
        $dob: String!
        $projectId: ID!
        $date: ISO8601Date!
      ) {
        clientSearch(
          input: { dob: $dob }
        ) {
          nodes {
            id
            activeEnrollment(projectId: $projectId, openOnDate: $date) {
              id
              entryDate
            }
          }
        }
      }
    GRAPHQL
  end

  # Give user access to view all clients. We are not testing client visibility permissions in this test.
  let!(:client_visibility_acl) { create_access_control(hmis_user, ds1, with_permission: :can_view_clients) }

  # give all clients the same dob so we can use the dob search input, which is simpler than text search
  let(:shared_client_dob) { 60.years.ago }

  # c1 has an active enrollment at p1
  let!(:c1) { create :hmis_hud_client, data_source: ds1, dob: shared_client_dob }
  let!(:c1_e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 1.week.ago }
  let!(:c1_e2) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 6.days.ago, exit_date: 6.days.ago } # cruft

  # c2 has an active enrollment at p2, and a closed enrollment at p1
  let!(:c2) { create :hmis_hud_client, data_source: ds1, dob: shared_client_dob }
  let!(:c2_e1) { create :hmis_hud_enrollment, data_source: ds1, client: c2, project: p2, entry_date: 1.week.ago }
  let!(:c2_e2) { create :hmis_hud_enrollment, data_source: ds1, client: c2, project: p1, entry_date: 2.months.ago, exit_date: 1.month.ago }

  describe 'when the user has full access' do
    let!(:access_control) { create_access_control(hmis_user, ds1) }

    it 'resolves activeEnrollment on multiple clients correctly' do
      response, result = post_graphql(dob: shared_client_dob, project_id: p1.id, date: 2.days.ago) { query }
      expect(response.status).to eq(200), result.inspect
      clients = result.dig('data', 'clientSearch', 'nodes').map(&:deep_symbolize_keys)
      expect(clients).to contain_exactly(
        # enrollment for c1 is included
        a_hash_including(id: c1.id.to_s, activeEnrollment: a_hash_including(id: c1_e1.id.to_s)),
        # enrollment for c2 is not included
        a_hash_including(id: c2.id.to_s, activeEnrollment: nil),
      )
    end

    it 'chooses one activeEnrollment if client has multiple' do
      # duplicate enrollment
      dup_c1_e1 = create(:hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 2.weeks.ago)

      response, result = post_graphql(dob: shared_client_dob, project_id: p1.id, date: 2.days.ago) { query }

      expect(response.status).to eq(200), result.inspect
      clients = result.dig('data', 'clientSearch', 'nodes').map(&:deep_symbolize_keys)
      expect(clients).to contain_exactly(
        a_hash_including(id: c1.id.to_s, activeEnrollment: a_hash_including(id: dup_c1_e1.id.to_s)),
        a_hash_including(id: c2.id.to_s, activeEnrollment: nil),
      )
    end

    it 'includes WIP enrollment as activeEnrollment' do
      c1_e1.save_in_progress!
      expect(c1_e1.ProjectID).to be_nil

      response, result = post_graphql(dob: shared_client_dob, project_id: p1.id, date: 2.days.ago) { query }

      expect(response.status).to eq(200), result.inspect
      clients = result.dig('data', 'clientSearch', 'nodes').map(&:deep_symbolize_keys)
      expect(clients).to contain_exactly(
        a_hash_including(id: c1.id.to_s, activeEnrollment: a_hash_including(id: c1_e1.id.to_s)),
        a_hash_including(id: c2.id.to_s, activeEnrollment: nil),
      )
    end

    it 'minimizes n+1 queries' do
      shared_client_dob = 50.years.ago
      20.times do
        c = create(:hmis_hud_client, data_source: ds1, dob: shared_client_dob)
        create(:hmis_hud_enrollment, data_source: ds1, client: c, project: p1, entry_date: 1.week.ago)
      end

      expect do
        _, result = post_graphql(dob: shared_client_dob, project_id: p1.id, date: 2.days.ago) { query }
        clients = result.dig('data', 'clientSearch', 'nodes').map(&:deep_symbolize_keys)
        expect(clients.size).to eq(20)
        # make sure each of them resolved an activeEnrollment
        expect(clients.map { |c| c[:activeEnrollment] }.compact.size).to eq(20)
      end.to make_database_queries(count: 10..35) # makes 29, but leaving some wiggle room
    end
  end

  describe 'when the user has access to only one project (p2)' do
    let!(:access_control) { create_access_control(hmis_user, p2) }

    it 'does not resolve activeEnrollments at p1' do
      response, result = post_graphql(dob: shared_client_dob, project_id: p1.id, date: 2.days.ago) { query }

      expect(response.status).to eq(200), result.inspect
      clients = result.dig('data', 'clientSearch', 'nodes').map(&:deep_symbolize_keys)
      expect(clients).to contain_exactly(
        # neither are included because we searched for active enrollments at p1
        a_hash_including(id: c1.id.to_s, activeEnrollment: nil),
        a_hash_including(id: c2.id.to_s, activeEnrollment: nil),
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
