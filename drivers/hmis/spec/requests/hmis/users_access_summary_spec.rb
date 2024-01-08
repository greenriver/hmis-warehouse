###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'User access summary query', type: :request do
  include_context 'hmis base setup'
  let!(:access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_audit_users, :can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end

  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Alice', last_name: 'Quinn' }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }

  let!(:other_hmis_user) do
    hmis_user2 = create(:user).related_hmis_user(ds1)
    # put them in an HMIS user group
    create_access_control(hmis_user2, ds1)
    hmis_user2
  end

  before(:each) { hmis_login(user) }

  let!(:now) { Time.current }

  enrollment_types = [
    ['Enrollment', :hmis_hud_enrollment],
    ['WIP Enrollment', :hmis_hud_wip_enrollment],
  ]

  enrollment_types.each do |enrollment_label, enrollment_factory|
    let!(:e1) { create enrollment_factory, data_source: ds1, project: p1, client: c1 }
    let!(:e2) { create enrollment_factory, data_source: ds1, project: p2, client: c2 }
    context "with #{enrollment_label} activity logs processed" do
      let!(:log1) do
        create :hmis_activity_log, resolved_fields: { "Enrollment/#{e1.id}" => [] }, data_source: ds1, user: other_hmis_user, created_at: now - 2.days
      end
      let!(:log2) do
        create :hmis_activity_log, resolved_fields: { "Enrollment/#{e2.id}" => [] }, data_source: ds1, user: other_hmis_user, created_at: now
      end
      before(:each) do
        Hmis::ActivityLogProcessorJob.perform_now
      end

      context 'client access summary' do
        subject(:query) do
          <<~GRAPHQL
            query testQuery($id: ID!, $filters: ClientAccessSummaryFilterOptions) {
              user(id: $id) {
                id
                clientAccessSummaries(limit: 10, offset: 0, filters: $filters) {
                  nodes {
                    id
                    lastAccessedAt
                    clientId
                    clientName
                  }
                }
              }
            }
          GRAPHQL
        end

        def run_query(id:, filters: nil)
          response, result = post_graphql(id: id, filters: filters) { query }
          expect(response.status).to eq(200), result.inspect
          result.dig('data', 'user', 'clientAccessSummaries', 'nodes')
        end

        it 'reports client access' do
          records = run_query(id: other_hmis_user.id)
          expect(records.size).to eq(2)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c1.id.to_s, c2.id.to_s)
        end

        it 'filters by client name' do
          records = run_query(id: other_hmis_user.id, filters: { searchTerm: c2.last_name })
          expect(records.size).to eq(1)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c2.id.to_s)
        end

        it 'filters by access date' do
          records = run_query(id: other_hmis_user.id, filters: { onOrAfter: log2.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') })
          expect(records.size).to eq(1)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c2.id.to_s)
        end
      end

      context 'enrollment access summary' do
        subject(:query) do
          <<~GRAPHQL
            query testQuery($id: ID!, $filters: EnrollmentAccessSummaryFilterOptions) {
              user(id: $id) {
                id
                enrollmentAccessSummaries(limit: 10, offset: 0, filters: $filters) {
                  nodes {
                    id
                    lastAccessedAt
                    clientId
                    clientName
                    enrollmentId
                    projectId
                  }
                }
              }
            }
          GRAPHQL
        end

        def run_query(id:, filters: nil)
          response, result = post_graphql(id: id, filters: filters) { query }
          expect(response.status).to eq(200), result.inspect
          result.dig('data', 'user', 'enrollmentAccessSummaries', 'nodes')
        end

        it 'reports enrollment access' do
          records = run_query(id: other_hmis_user.id)
          expect(records.size).to eq(2)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c1.id.to_s, c2.id.to_s)
          expect(records.map { |h| h['enrollmentId'] }).to contain_exactly(e1.id.to_s, e2.id.to_s)
          expect(records.map { |h| h['projectId'] }).to contain_exactly(p1.id.to_s, p2.id.to_s)
        end

        it 'filters by client name' do
          records = run_query(id: other_hmis_user.id, filters: { searchTerm: c2.last_name })
          expect(records.size).to eq(1)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c2.id.to_s)
        end

        it 'filters by access date' do
          records = run_query(id: other_hmis_user.id, filters: { onOrAfter: log2.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') })
          expect(records.size).to eq(1)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c2.id.to_s)
        end

        it 'filters by project id' do
          records = run_query(id: other_hmis_user.id, filters: { project: p1.id })
          expect(records.size).to eq(1)
          expect(records.map { |h| h['clientId'] }).to contain_exactly(c1.id.to_s)
        end
      end
    end
  end
end
