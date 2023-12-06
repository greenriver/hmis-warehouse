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
      query GetClient($id: ID!) {
        client(id: $id) {
          id
          auditHistory(limit: 10, offset: 0) {
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

  before(:all) do
    @paper_trail_was = PaperTrail.enabled?
    PaperTrail.enabled = true
  end
  after(:all) do
    PaperTrail.enabled = @paper_trail_was
  end

  before(:each) { hmis_login(user) }

  def run_query(id:)
    response, result = post_graphql(id: id) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'client', 'auditHistory', 'nodes')
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

RSpec.configure do |c|
  c.include GraphqlHelpers
end
