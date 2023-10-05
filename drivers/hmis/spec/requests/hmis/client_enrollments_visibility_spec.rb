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
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1 }
  let!(:s2) { create :hmis_hud_service, data_source: ds1, enrollment: e2, client: c1 }

  before(:each) do
    hmis_login(user)
  end

  describe 'client enrollments query' do
    let(:query) do
      <<~GRAPHQL
        query TestQuery($id: ID!) {
          client(id: $id) {
            id
            enrollments(limit: 10, offset: 0) {
              nodes {
                id
              }
            }
            services(limit: 10, offset: 0) {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves only services and enrollments at visible projects' do
      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq 200

      aggregate_failures 'checking response' do
        [e1].map(&:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          enrollments = result.dig('data', 'client', 'enrollments', 'nodes')
          expect(enrollments.map { |r| r.fetch('id') }).to eq(expected)
        end
        c1.hmis_services.where(enrollment_id: e1.enrollment_id).map(&:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          services = result.dig('data', 'client', 'services', 'nodes')
          expect(services.map { |r| r.fetch('id') }).to eq(expected)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
