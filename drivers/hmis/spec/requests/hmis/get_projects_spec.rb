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

  let!(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2, user: u1 } # This one shouldn't be viewable by this user
  let!(:p3) { create :hmis_hud_project, project_name: 'TestProject - Name/with=special_chars', data_source: ds1, organization: o1, user: u1, project_type: 2 }

  let(:query) do
    <<~GRAPHQL
      query GetProject($projectTypes: [ProjectType!], $searchTerm: String, $sortOrder: ProjectSortOption, $offset: Int = 0, $limit: Int = 5) {
        projects(filters: { projectTypes: $projectTypes, searchTerm: $searchTerm }, sortOrder: $sortOrder, offset: $offset, limit: $limit) {
          nodesCount
          nodes {
            #{scalar_fields(Types::HmisSchema::Project)}
          }
        }
      }
    GRAPHQL
  end

  def search(**input)
    aggregate_failures 'checking response' do
      response, result = post_graphql(input) { query }
      expect(response.status).to eq 200
      project = result.dig('data', 'projects')
      yield project
    end
  end

  before(:each) do
    hmis_login(user)
    assign_viewable(view_access_group, o1, hmis_user)
  end

  it 'should return projects correctly without filters' do
    search do |projects|
      # Shouldn't return p2 since its org isn't viewable to us
      expect(projects).to include(
        'nodesCount' => 2,
        'nodes' => contain_exactly(include('id' => p1.id.to_s), include('id' => p3.id.to_s)),
      )
    end
  end

  it 'should return projects correctly with project type filter' do
    search(project_types: [Types::HmisSchema::Enums::ProjectType.key_for(p3.project_type)]) do |projects|
      expect(projects).to include(
        'nodesCount' => 1,
        'nodes' => contain_exactly(include('id' => p3.id.to_s)),
      )
    end
  end

  describe 'with search term' do
    def check_search_term(term, expected_projects)
      search(search_term: term) do |projects|
        expect(projects).to include(
          'nodesCount' => expected_projects.size,
          'nodes' => contain_exactly(*expected_projects.map { |p| include('id' => p.id.to_s) }),
        )
      end
    end

    it 'Should match search terms correctly' do
      [
        [
          'project', # Search term
          [p1, p3], # Expected results
          -> { p1.update(project_name: 'Project 1') }, # Test setup (optional)
        ],
        ['TestProject - ', [p3]],
        ['TestProject - Name/with=special_chars', [p3]],
        ['test name special', [p3]],
        # Add more search term tests here
      ].each do |term, expected, setup|
        setup&.call
        check_search_term(term, expected)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
