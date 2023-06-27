###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:c2) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:e2_wip) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  describe 'project query' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
      e2_wip.save_in_progress
    end

    let(:query) do
      <<~GRAPHQL
        query GetProject($id: ID!) {
          project(id: $id) {
            id
            enrollments(limit: 10, offset: 0) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    let(:wip_only_query) do
      <<~GRAPHQL
        query GetProject($id: ID!) {
          project(id: $id) {
            id
            enrollments(limit: 10, offset: 0, enrollmentLimit: WIP_ONLY) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    let(:non_wip_query) do
      <<~GRAPHQL
        query GetProject($id: ID!) {
          project(id: $id) {
            id
            enrollments(limit: 10, offset: 0, enrollmentLimit: NON_WIP_ONLY) {
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
        expect(response.status).to eq 200
        enrollments = result.dig('data', 'project', 'enrollments', 'nodes')
        expect(enrollments.size).to eq(2)
      end
    end

    it 'applies WIP-only limit' do
      response, result = post_graphql(id: p1.id) { wip_only_query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        enrollments = result.dig('data', 'project', 'enrollments', 'nodes')
        expect(enrollments.size).to eq(1)
        expect(enrollments[0]['id']).to eq(e2_wip.id.to_s)
      end
    end

    it 'applies non-WIP-only limit' do
      response, result = post_graphql(id: p1.id) { non_wip_query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
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
