###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'DeleteProjectConfig Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteProjectConfig($id: ID!) {
        deleteProjectConfig(id: $id) {
          projectConfig {
            id
            configType
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

  it 'successfully soft-deletes a project config' do
    response, result = post_graphql(id: project_config.id) { mutation }

    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'deleteProjectConfig', 'errors')).to be_empty
    expect(result.dig('data', 'deleteProjectConfig', 'projectConfig')).to include(
      'id' => project_config.id.to_s,
      'configType' => 'AUTO_ENTER',
    )
    expect(project_config.reload.deleted_at).to be_present
    expect(Hmis::ProjectAutoEnterConfig.for_project(p1)).to be_empty
  end

  it 'throws an error when the user does not have access' do
    remove_permissions(access_control, :can_configure_data_collection)
    expect_access_denied(post_graphql(id: project_config.id) { mutation })
  end
end
