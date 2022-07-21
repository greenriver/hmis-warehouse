require './drivers/hmis/spec/support/graphql_helpers'
require 'rails_helper'

RSpec.configure do |c|
  c.include GraphqlHelpers
end

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:user) { create :user }
  let!(:ds1) { create :source_data_source, id: 1, hmis: GraphqlHelpers::HMIS_HOSTNAME }
  let!(:o1) { create :hud_organization, OrganizationName: 'ZZZ', data_source_id: ds1.id }
  let!(:p1) { create :hud_project, ProjectName: 'BBB', data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:p2) { create :hud_project, ProjectName: 'AAA', data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:o2) { create :hud_organization, OrganizationName: 'XXX', data_source_id: ds1.id }
  let!(:p3) { create :hud_project, ProjectName: 'DDD', data_source_id: ds1.id, OrganizationID: o2.OrganizationID }
  let!(:p4) { create :hud_project, ProjectName: 'CCC', data_source_id: ds1.id, OrganizationID: o2.OrganizationID }

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  describe 'Projects query' do
    it 'sorts by name' do
      result = post_graphql do
        <<~GRAPHQL
          query {
            projects(sortOrder: NAME) {
              projectName
            }
          }
        GRAPHQL
      end

      project_names = result.dig('data', 'projects').map { |d| d['projectName'] }
      expect(project_names).to eq ['AAA', 'BBB', 'CCC', 'DDD']
    end

    it 'sorts by organization and name' do
      result = post_graphql do
        <<~GRAPHQL
          query {
            projects(sortOrder: ORGANIZATION_AND_NAME) {
              projectName
              organization {
                organizationName
              }
            }
          }
        GRAPHQL
      end

      organization_names = result.dig('data', 'projects').map { |d| d['organization']['organizationName'] }
      expect(organization_names).to eq ['XXX', 'XXX', 'ZZZ', 'ZZZ']
      project_names = result.dig('data', 'projects').map { |d| d['projectName'] }
      expect(project_names).to eq ['CCC', 'DDD', 'AAA', 'BBB']
    end
  end
end
