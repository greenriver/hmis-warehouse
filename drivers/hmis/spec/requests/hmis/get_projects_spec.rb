###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'GetProjects query', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, o1) }
  let!(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2, user: u1 } # This one shouldn't be viewable by this user
  let!(:p3) { create :hmis_hud_project, project_name: 'TestProject - Name/with=special_chars', data_source: ds1, organization: o1, user: u1, project_type: 2 }

  before(:each) do
    hmis_login(user)
  end

  # This query matches the GetProjects query made by the frontend
  let(:query) do
    <<~GRAPHQL
      query GetProjects(
        $limit: Int = 25
        $offset: Int = 0
        $filters: ProjectFilterOptions
        $sortOrder: ProjectSortOption
      ) {
        projects(
          limit: $limit
          offset: $offset
          filters: $filters
          sortOrder: $sortOrder
        ) {
          offset
          limit
          nodesCount
          nodes {
            id
            projectName
            projectType
            operatingStartDate
            operatingEndDate
            organization {
              id
              hudId
              organizationName
            }
          }
        }
      }
    GRAPHQL
  end

  def perform_query(**input)
    aggregate_failures 'checking response' do
      response, result = post_graphql(**input) { query }
      expect(response.status).to eq(200), result.inspect
      projects = result.dig('data', 'projects')
      yield projects
    end
  end

  it 'returns viewable projects' do
    perform_query do |projects|
      # Shouldn't return p2 since its org isn't viewable to user
      expect(projects).to include(
        'nodesCount' => 2,
        'nodes' => contain_exactly(include('id' => p1.id.to_s), include('id' => p3.id.to_s)),
      )
    end
  end

  it 'filters by project type' do
    perform_query(filters: { project_type: [Types::HmisSchema::Enums::ProjectType.key_for(p3.project_type)] }) do |projects|
      expect(projects).to include(
        'nodesCount' => 1,
        'nodes' => contain_exactly(include('id' => p3.id.to_s)),
      )
    end
  end

  it 'responds with 401 if not authenticated' do
    # Clear JWT headers to simulate unauthenticated request
    # (hmis_login in before(:each) sets up @jwt_headers)
    @jwt_headers = {}
    response, body = post_graphql { query }
    expect(response.status).to eq 401
    expect(body.dig('error', 'type')).to eq 'unauthenticated'
  end

  context 'sorting' do
    # Update names and create additional projects to validate sorting
    let!(:o1) { create :hmis_hud_organization, OrganizationName: 'ZZZ', data_source: ds1 }
    let!(:p1) { create :hmis_hud_project, ProjectName: 'BBB', data_source: ds1, organization: o1 }
    let!(:p2) { create :hmis_hud_project, ProjectName: 'AAA', data_source: ds1, organization: o1 }
    let!(:o2) { create :hmis_hud_organization, OrganizationName: 'XXX', data_source: ds1 }
    let!(:p3) { create :hmis_hud_project, ProjectName: 'DDD', data_source: ds1, organization: o2 }
    let!(:p4) { create :hmis_hud_project, ProjectName: 'CCC', data_source: ds1, organization: o2 }
    # Give user access to view all projects
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: :can_view_project) }

    it 'sorts by project name' do
      perform_query(sort_order: 'NAME') do |projects|
        project_names = projects.dig('nodes').map { |d| d['projectName'] }
        expect(project_names).to eq ['AAA', 'BBB', 'CCC', 'DDD']
      end
    end

    it 'sorts by organization name and project name' do
      perform_query(sort_order: 'ORGANIZATION_AND_NAME') do |projects|
        organization_names = projects.dig('nodes').map { |d| d['organization']['organizationName'] }
        expect(organization_names).to eq ['XXX', 'XXX', 'ZZZ', 'ZZZ']
        project_names = projects.dig('nodes').map { |d| d['projectName'] }
        expect(project_names).to eq ['CCC', 'DDD', 'AAA', 'BBB']
      end
    end
  end

  describe 'with search term' do
    def check_search_term(term, expected_projects)
      perform_query(filters: { search_term: term }) do |projects|
        expect(projects).to include(
          'nodesCount' => expected_projects.size,
          'nodes' => contain_exactly(*expected_projects.map { |p| include('id' => p.id.to_s) }),
        )
      end
    end

    it 'filters by search terms' do
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

    it 'does not error when passed a large integer value (regression test)' do
      check_search_term('73892738928', [])
    end
  end

  context 'with 50+ projects' do
    before(:each) do
      create_list(:hmis_hud_project, 50, data_source: ds1, organization: o1)
    end

    it 'minimizes n+1 queries' do
      expect do
        response, result = post_graphql(limit: 50) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'projects', 'nodes').size).to eq(50)
      end.to make_database_queries(count: 1..20)
    end

    it 'is responsive' do
      expect do
        response, result = post_graphql(limit: 50) { query }
        expect(response.status).to eq(200), result.inspect
      end.to perform_under(150).ms
    end
  end

  context 'when there are multiple HMIS data sources' do
    let!(:ds2) { create :hmis_data_source }
    let!(:ds2_project) { create :hmis_hud_project, data_source: ds2 }
    # Give user access to view all projects in ds2
    let!(:ds2_access_control) { create_access_control(hmis_user, ds2) }

    it 'does not include projects from other data sources' do
      perform_query do |projects|
        expect(projects.dig('nodes')).not_to include(include('id' => ds2_project.id.to_s))
      end
    end

    it 'fails authorization check if project leaked through viewable_by scope (related to regression #6758)' do
      # Mock a scenario where Project viewable_by scope incorrectly returns a project in ds2.
      # (This wouldn't happen in real life thanks to the viewable_by scope filtering to projects in the users current data source (user.hmis_data_source_id))
      expect(Hmis::Hud::Project).to receive(:viewable_by).and_return(Hmis::Hud::Project.where(id: ds2_project.id))

      expect { perform_query }.to raise_error(/failed authorization check/)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
