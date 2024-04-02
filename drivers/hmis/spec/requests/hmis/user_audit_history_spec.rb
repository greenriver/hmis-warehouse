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
      PaperTrail.request(controller_info: { true_user_id: hmis_user.id }) do
        c1.update!(Man: 0)
      end
    end
    it 'should return audit history of user' do
      records = run_query(id: hmis_user.id)
      expect(records.size).to eq(1)
      expect(records[0]['event']).to eq('update')
      expect(records[0]['recordName']).to eq('Client')
    end
  end

  context 'user who created a custom assessment' do
    before(:each) do
      fd = create(:hmis_form_definition, identifier: 'custom-service-def2', role: 'CUSTOM_ASSESSMENT', title: 'A very custom assessment')
      fp = create(:hmis_form_processor, definition: fd)

      PaperTrail.request(controller_info: { true_user_id: hmis_user.id }) do
        a = create(:hmis_custom_assessment, data_collection_stage: 7, data_source: ds1, enrollment: e1)
        a.form_processor = fp
        a.definition = fd
        a.save!
      end
    end
    it 'should return audit history with custom assessment title' do
      records = run_query(id: hmis_user.id)
      expect(records.pluck('recordName')).to include('A very custom assessment')
    end
  end

  context 'user who does not have permission to see client name' do
    let!(:access_control) do
      create_access_control(hmis_user, ds1, without_permission: :can_view_client_name)
    end
    before(:each) do
      PaperTrail.request(controller_info: { true_user_id: hmis_user.id }) do
        c1.update!(FirstName: 'Top secret')
      end
    end
    it 'should return client with masked name' do
      records = run_query(id: hmis_user.id)
      expect(records.size).to eq(1)
      expect(records[0]['event']).to eq('update')
      expect(records[0].dig('objectChanges', 'firstName', 'values')).to eq('changed'), 'Should see that it was changed but not the actual values'
    end
  end
end
