###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'UpdateProjectConfig Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation UpdateProjectConfig($id: ID!, $input: ProjectConfigInput!) {
        updateProjectConfig(id: $id, input: $input) {
          projectConfig {
            id
            configType
            configOptions
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:project_config) { create(:hmis_project_auto_enter_config, project: p1, data_source: ds1) }

  before(:each) do
    hmis_login(user)
  end

  it 'successfully updates a project config' do
    auto_exit_config = create(:hmis_project_auto_exit_config, project: p1, data_source: ds1, length_of_absence_days: 30)
    response, result = post_graphql(id: auto_exit_config.id, input: { length_of_absence_days: 45 }) { mutation }

    expect(response.status).to eq(200), result.inspect
    expect(JSON.parse(result.dig('data', 'updateProjectConfig', 'projectConfig', 'configOptions'))).to eq('length_of_absence_days' => 45)
    expect(auto_exit_config.reload.length_of_absence_days).to eq(45)
  end

  it 'throws an error when the user does not have access' do
    remove_permissions(access_control, :can_configure_data_collection)
    expect_access_denied(post_graphql(id: project_config.id, input: { config_type: 'AUTO_ENTER' }) { mutation })
  end

  it 'returns a validation error when config type changes' do
    response, result = post_graphql(id: project_config.id, input: { config_type: 'AUTO_EXIT', length_of_absence_days: 30 }) { mutation }

    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateProjectConfig', 'projectConfig')).to be_nil
    expect(result.dig('data', 'updateProjectConfig', 'errors')).to contain_exactly(
      a_hash_including('attribute' => 'configType', 'message' => 'cannot be changed once set'),
    )
  end
end
