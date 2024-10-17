#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

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

  before(:each) do
    hmis_login(user)
  end

  include_context 'hmis base setup'

  let(:create_project_config) do
    <<~GRAPHQL
      mutation CreateProjectConfig($input: ProjectConfigInput!) {
        createProjectConfig(input: $input) {
          projectConfig {
            id
            configType
            organizationId
            organization {
              id
              organizationName
            }
            projectId
            project {
              id
              projectName
            }
            projectType
            configOptions
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:get_project_configs) do
    <<~GRAPHQL
      query GetProjectConfigs {
        projectConfigs {
          nodesCount
          nodes {
            id
          }
        }
      }
    GRAPHQL
  end

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  it 'should successfully create a new auto enter config' do
    mutation_input = { config_type: 'AUTO_ENTER', project_type: 'ES_ENTRY_EXIT' }
    response, result = post_graphql(input: mutation_input) { create_project_config }
    expect(response.status).to eq(200), result.inspect
    project_config_id = result.dig('data', 'createProjectConfig', 'projectConfig', 'id')
    expect(project_config_id).not_to be_nil
    project_config = Hmis::ProjectConfig.find(project_config_id)
    expect(project_config.class.name).to eq('Hmis::ProjectAutoEnterConfig')
    expect(project_config.project_type).to eq(0)
  end

  it 'should throw an error when the user does not have access' do
    remove_permissions(access_control, :can_configure_data_collection)
    mutation_input = { config_type: 'AUTO_ENTER', project_type: 'ES_ENTRY_EXIT' }
    expect_access_denied(post_graphql(input: mutation_input) { create_project_config })
  end

  describe 'when there are multiple hmis data sources' do
    let!(:ds2) { create :hmis_data_source }
    let!(:p2) { create :hmis_hud_project, data_source: ds2 }
    let!(:ds2_access_control) { create_access_control(hmis_user, ds2) }
    let!(:ds1_project_config) { create :hmis_project_auto_enter_config, project: p1 }
    let!(:ds2_project_config) { create :hmis_project_auto_enter_config, project: p2 }

    it 'should do return only the configs in the current data source' do
      response, result = post_graphql { get_project_configs }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'projectConfigs', 'nodesCount')).to eq(1)
      expect(result.dig('data', 'projectConfigs', 'nodes', 0, 'id')).to eq(ds1_project_config.id.to_s)
    end
  end
end
