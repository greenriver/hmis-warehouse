###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiConfigsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:admin_role) { create(:role, can_view_projects: true, can_edit_data_sources: true, can_manage_config: true) }
  let(:viewer_role) { create(:role, can_view_projects: true) }
  let(:edit_collection) { create(:collection) }
  let(:view_collection) { create(:collection) }
  let(:editable_data_source) { create(:source_data_source) }
  let(:view_only_data_source) { create(:source_data_source) }
  let(:viewed_project) { create(:hud_project, data_source: view_only_data_source) }

  def create_config(data_source)
    GrdaWarehouse::EtoApiConfig.create!(
      data_source_id: data_source.id,
      identifier: 'original-identifier',
      email: 'eto@example.com',
      password: 'ETO-PASSWORD',
      enterprise: 'enterprise',
      touchpoint_fields: {},
      demographic_fields: {},
      demographic_fields_with_attributes: {},
      additional_fields: {},
    )
  end

  let!(:editable_config) { create_config(editable_data_source) }
  let!(:view_only_config) { create_config(view_only_data_source) }

  before do
    edit_collection.set_viewables({ data_sources: [editable_data_source.id] })
    view_collection.set_viewables({ projects: [viewed_project.id] })
    setup_access_control(user, admin_role, edit_collection)
    setup_access_control(user, viewer_role, view_collection)
    sign_in user
  end

  it 'does not render the edit page, which shows the ETO password, for a data source the user can only view' do
    get edit_data_source_api_config_path(view_only_data_source)
    expect(response).to have_http_status(:not_found)
  end

  it 'does not update the config of a data source the user can only view' do
    patch data_source_api_config_path(view_only_data_source), params: { config: { identifier: 'changed' } }
    expect(response).to have_http_status(:not_found)
    expect(view_only_config.reload.identifier).to eq('original-identifier')
  end

  it 'still renders the config on the data source the role covers' do
    get edit_data_source_api_config_path(editable_data_source)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('original-identifier')
  end
end
