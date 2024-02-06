#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'User Audit History Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query GetUser($id: ID!, $filters: UserAuditEventFilterOptions) {
        user(id: $id) {
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
    create_access_control(hmis_user, ds1)
  end
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  before(:each) { hmis_login(user) }

  def run_query(id:, filters: nil)
    response, result = post_graphql(id: id, filters: filters) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'user', 'auditHistory', 'nodes')
  end

  context 'user who created a client' do
    before(:each) do
      PaperTrail.request(controller_info: { user_id: hmis_user.id }) do
        c1.update!(Man: 0)
      end
    end
    it 'should return audit history of user' do
      records = run_query(id: hmis_user.id)
      expect(records.size).to eq(1)
      expect(records[0]['event']).to eq('update')
      expect(records[0]['recordName']).to eq('Client')
    end

    # TODO @MARTHA - get rid of this and add a test for the functionality I'm adding here
    it 'should be able to reproduce this bad error' do
      filters = GraphQL::Execution::Interpreter::Arguments.new(argument_values: {}).freeze
      scope = GrdaWarehouse.paper_trail_versions.
        where(user_id: hmis_user.id).
        where.not(object_changes: nil, event: 'update').
        unscope(:order). # Unscope to remove default order, otherwise it will conflict
        order(created_at: :desc)
      result = Hmis::Filter::PaperTrailVersionFilter.new(filters).filter_scope(scope)
      expect(result).not_to be_nil
    end
  end
end
