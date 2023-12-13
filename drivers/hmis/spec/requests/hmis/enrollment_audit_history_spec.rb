###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Client Audit History Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query TestQuery($id: ID!, $filters: BaseAuditEventFilterOptions!) {
        enrollment(id: $id) {
          id
          auditHistory(limit: 10, offset: 0, filters: $filters) {
            nodes {
              id
              createdAt
              event
              objectChanges
              recordName
              recordId
              user {
                id
                name
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details, :can_audit_enrollments])
  end
  let(:today) { Date.current }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: today }

  before(:each) { hmis_login(user) }

  def run_query(id:, filters:)
    response, result = post_graphql(id: id, filters: filters) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'enrollment', 'auditHistory', 'nodes')
  end

  context 'enrollment with history' do
    before(:each) do
      PaperTrail.request(controller_info: { user_id: hmis_user.id }) do
        e1.update!(entry_date: (today - 2.days))
      end
    end
    it 'reports change' do
      records = run_query(id: e1.id, filters: { audit_event_record_type: ['Hmis::Hud::Enrollment'], user: [hmis_user.id.to_s] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'objectChanges', 'entryDate', 'values')).
        to eq([today, today - 2.days].map { |d| d.to_s(:db) })
    end
  end
end
