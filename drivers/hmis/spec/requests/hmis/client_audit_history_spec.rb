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
      query GetClient($id: ID!, $filters: ClientAuditEventFilterOptions) {
        client(id: $id) {
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
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) { hmis_login(user) }

  def run_query(id:, filters: nil)
    response, result = post_graphql(id: id, filters: filters) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'client', 'auditHistory', 'nodes')
  end

  context 'client updated by several users' do
    let!(:user2) { create(:user) }
    let!(:hmis_user2) { user2.related_hmis_user(ds1) }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1 }

    before(:each) do
      PaperTrail.request(controller_info: { user_id: hmis_user.id }) do
        c1.update!(Man: 0)
      end
      PaperTrail.request(controller_info: { user_id: hmis_user2.id }) do
        c1.update!(Man: 1)
      end
    end
    it 'filters users' do
      records = run_query(id: c1.id, filters: { user: [hmis_user2.id.to_s] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'objectChanges', 'gender', 'values')).to eq([nil, ['MAN']])
    end
  end

  context 'client with demographics and address change' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1 }
    before(:each) do
      c1.update!(Man: 0)
      create(:hmis_hud_custom_client_address, client: c1, data_source: ds1)
    end
    it 'filters by address record type' do
      records = run_query(id: c1.id, filters: { client_record_type: ['Hmis::Hud::CustomClientAddress'] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'recordName')).to eq('Address')
    end
  end

  context 'client record with two genders' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1, CulturallySpecific: 1 }
    context 'changing to one gender' do
      before(:each) { c1.update!(Man: 0) }
      it 'reports change' do
        records = run_query(id: c1.id)
        expect(records.size).to eq(2)
        expect(records.dig(0, 'objectChanges', 'gender', 'values')).to eq([['MAN', 'CULTURALLY_SPECIFIC'], ['CULTURALLY_SPECIFIC']])
        expect(records.dig(1, 'objectChanges', 'gender', 'values')).to eq([nil, ['MAN', 'CULTURALLY_SPECIFIC']])
      end
    end
  end

  context 'client record with no race' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, RaceNone: nil, HispanicLatinaeo: nil }
    context 'changing to one race' do
      before(:each) { c1.update!(HispanicLatinaeo: 1) }
      it 'reports change' do
        records = run_query(id: c1.id)
        expect(records.size).to eq(2)
        expect(records.dig(0, 'objectChanges', 'race', 'values')).to eq([nil, ['HISPANIC_LATINAEO']])
        expect(records.dig(1, 'objectChanges', 'race', 'values')).to be_nil
      end
    end
  end
end
