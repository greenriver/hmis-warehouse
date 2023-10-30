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
  let!(:a1) { create :hmis_hud_assessment, data_source: e1.data_source, enrollment: e1, client: c1 }

  # override base setup
  let!(:cst1) { create :hmis_custom_service_type_for_hud_service, data_source: ds1, custom_service_category: csc1, user: u1 }

  # canary values
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:access_control2) { create_access_control(hmis_user, p2, with_permission: :can_view_clients) }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, sexual_orientation: 2 }
  let!(:s2) { create :hmis_hud_service, data_source: ds1, enrollment: e2, client: c1 }
  let!(:a2) { create :hmis_hud_assessment, data_source: e1.data_source, enrollment: e2, client: c1 }

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
                entryDate # limited-access
                projectName # limited-access
                sexualOrientation # detail-access
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
      expect(response.status).to eq(200), result.inspect

      aggregate_failures 'checking response' do
        [e1].map(&:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          enrollments = result.dig('data', 'client', 'enrollments', 'nodes')
          expect(enrollments.map { |r| r.fetch('id') }).to contain_exactly(*expected)
        end
        c1.hmis_services.where(enrollment_id: e1.enrollment_id).map(&:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          services = result.dig('data', 'client', 'services', 'nodes')
          expect(services.map { |r| r.fetch('id') }).to contain_exactly(*expected)
        end
      end
    end

    it 'resolves enrollment where user has limited access (but not services)' do
      create_access_control(hmis_user, p2, with_permission: :can_view_limited_enrollment_details)

      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq(200), result.inspect

      aggregate_failures 'checking response' do
        [e1, e2].map(&:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 2
          enrollments = result.dig('data', 'client', 'enrollments', 'nodes')
          expect(enrollments.map { |r| r.fetch('id') }).to contain_exactly(*expected)

          # enrollment details should not be present on limited enrollment (e2)
          resolved_e2 = enrollments.find { |e| e['id'] == e2.id.to_s }
          expect(e2.sexual_orientation).to be_present
          expect(resolved_e2['sexualOrientation']).to be_nil # redacted due to permissions
          expect(resolved_e2['entryDate']).to be_present
          expect(resolved_e2['projectName']).to be_present
        end

        # Only resolves services for e1
        c1.hmis_services.where(enrollment_id: e1.enrollment_id).map(&:id).map(&:to_s).tap do |expected|
          expect(expected.size).to eq 1
          services = result.dig('data', 'client', 'services', 'nodes')
          expect(services.map { |r| r.fetch('id') }).to contain_exactly(*expected)
        end
      end
    end

    describe 'resolving limited-access enrollments' do
      let!(:limited_access_control) { create_access_control(hmis_user, p2, with_permission: :can_view_limited_enrollment_details) }
      let(:query_with_project) do
        <<~GRAPHQL
          query TestQuery($id: ID!) {
            client(id: $id) {
              id
              enrollments(limit: 10, offset: 0) {
                nodes {
                  id
                  project { # detail-access non-nullable, will error
                    id
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      let(:query_with_assessments) do
        <<~GRAPHQL
          query TestQuery($id: ID!) {
            client(id: $id) {
              id
              enrollments(limit: 10, offset: 0) {
                nodes {
                  id
                  assessments { # detail-access non-nullable, will error
                    nodes {
                      id
                    }
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      it 'errors if attempting to resolve project on a limited-access enrollment' do
        expect { post_graphql(id: c1.id) { query_with_project } }.to raise_error(StandardError)
      end

      it 'errors if attempting to resolve assessments on a limited-access enrollment' do
        expect { post_graphql(id: c1.id) { query_with_assessments } }.to raise_error(StandardError)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
