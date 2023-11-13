###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:c2) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:e2_wip) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1 }

  describe 'project query' do
    before(:each) do
      hmis_login(user)
    end

    let(:query) do
      <<~GRAPHQL
        query GetProject($id: ID!, $status: [EnrollmentFilterOptionStatus!]) {
          project(id: $id) {
            id
            enrollments(limit: 10, offset: 0, filters: { status: $status }) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves WIP and non-WIP by default' do
      response, result = post_graphql(id: p1.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result.inspect
        enrollments = result.dig('data', 'project', 'enrollments', 'nodes').map { |n| n['id'] }
        expect(enrollments.size).to eq(2)
        expect(enrollments).to contain_exactly(e1.id.to_s, e2_wip.id.to_s)
      end
    end

    it 'applies WIP-only filter' do
      response, result = post_graphql(id: p1.id, status: ['INCOMPLETE']) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result.inspect
        enrollments = result.dig('data', 'project', 'enrollments', 'nodes')
        expect(enrollments.size).to eq(1)
        expect(enrollments[0]['id']).to eq(e2_wip.id.to_s)
      end
    end

    it 'applies non-WIP-only filter' do
      response, result = post_graphql(id: p1.id, status: ['ACTIVE', 'EXITED']) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result.inspect
        enrollments = result.dig('data', 'project', 'enrollments', 'nodes')
        expect(enrollments.size).to eq(1)
        expect(enrollments[0]['id']).to eq(e1.id.to_s)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
