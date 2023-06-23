###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let!(:o1) { create :hmis_hud_organization, OrganizationName: 'ZZZ', data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, ProjectName: 'BBB', data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, ProjectName: 'AAA', data_source: ds1, organization: o1 }
  let!(:o2) { create :hmis_hud_organization, OrganizationName: 'XXX', data_source: ds1 }
  let!(:p3) { create :hmis_hud_project, ProjectName: 'DDD', data_source: ds1, organization: o2 }
  let!(:p4) { create :hmis_hud_project, ProjectName: 'CCC', data_source: ds1, organization: o2 }
  let(:simple_query) do
    <<~GRAPHQL
      query {
        projects {
          nodes {
            projectName
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'Projects query' do
    it 'sorts by name' do
      response, result = post_graphql do
        <<~GRAPHQL
          query {
            projects(sortOrder: NAME) {
              nodes {
                projectName
              }
            }
          }
        GRAPHQL
      end

      expect(response.status).to eq 200
      project_names = result.dig('data', 'projects', 'nodes').map { |d| d['projectName'] }
      expect(project_names).to eq ['AAA', 'BBB', 'CCC', 'DDD']
    end

    it 'sorts by organization and name' do
      response, result = post_graphql do
        <<~GRAPHQL
          query {
            projects(sortOrder: ORGANIZATION_AND_NAME) {
              nodes {
                projectName
                organization {
                  organizationName
                }
              }
            }
          }
        GRAPHQL
      end
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        organization_names = result.dig('data', 'projects', 'nodes').map { |d| d['organization']['organizationName'] }
        expect(organization_names).to eq ['XXX', 'XXX', 'ZZZ', 'ZZZ']
        project_names = result.dig('data', 'projects', 'nodes').map { |d| d['projectName'] }
        expect(project_names).to eq ['CCC', 'DDD', 'AAA', 'BBB']
      end
    end

    it 'responds with 401 if not authenticated' do
      delete destroy_hmis_user_session_path
      aggregate_failures 'checking response' do
        expect(response.status).to eq 204
        response, body = post_graphql { simple_query }
        expect(response.status).to eq 401
        expect(body.dig('error', 'type')).to eq 'unauthenticated'
      end
    end
  end

  it 'is responsive' do
    expect do
      response, _result = post_graphql { simple_query }
      expect(response.status).to eq 200
    end.to query_limit_lt(20)
    expect do
      response, _result = post_graphql { simple_query }
      expect(response.status).to eq 200
    end.to perform_under(100).ms
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
