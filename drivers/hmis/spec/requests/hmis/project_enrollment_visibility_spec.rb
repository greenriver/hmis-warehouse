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
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, enrollment: e1, client: c1 }

  # override base setup
  let!(:cst1) { create :hmis_custom_service_type_for_hud_service, data_source: ds1, custom_service_category: csc1, user: u1 }

  # canary values
  let!(:ed1) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1).tap(&:destroy!) }
  let!(:sd1) { create(:hmis_hud_service, data_source: ds1, enrollment: e1, client: c1).tap(&:destroy!) }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1 }
  let!(:s2) { create :hmis_hud_service, data_source: ds1, enrollment: e2, client: c1 }

  before(:each) do
    hmis_login(user)
  end

  describe 'project services & enrollments query' do
    let(:query) do
      <<~GRAPHQL
        query TestQuery($id: ID!) {
          project(id: $id) {
            id
            services(limit: 10, offset: 0) {
              nodesCount
              nodes {
                id
              }
            }
            enrollments(limit: 10, offset: 0) {
              nodesCount
              nodes {
                id
              }
            }
            households(limit: 10, offset: 0) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    it 'includes only services & enrollments at this project' do
      response, result = post_graphql(id: p1.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200

        p1.hmis_services.pluck(:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          services = result.dig('data', 'project', 'services', 'nodes')
          expect(services.map { |r| r.fetch('id') }).to eq expected
        end

        p1.enrollments.pluck(:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          enrollments = result.dig('data', 'project', 'enrollments', 'nodes')
          expect(enrollments.map { |r| r.fetch('id') }).to eq expected
        end

        p1.households.pluck(:household_id).tap do |expected|
          expect(expected.size).to eq 1
          households = result.dig('data', 'project', 'households', 'nodes')
          expect(households.map { |r| r.fetch('id') }).to eq expected
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
