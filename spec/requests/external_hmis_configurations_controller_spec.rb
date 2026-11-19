###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalHmisConfigurationsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:editor_role) { create(:role, can_view_projects: true, can_edit_data_sources: true) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }
  let(:project) { create(:hud_project, data_source: data_source) }
  let(:update_params) { { grda_warehouse_external_hmis_configuration: { base_url: 'https://changed.example' } } }

  before { sign_in user }

  def saved_base_url
    GrdaWarehouse::ExternalHmisConfiguration.find_by(data_source_id: data_source.id)&.base_url
  end

  context 'when the edit permission covers only one project of the data source' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, editor_role, collection)
    end

    it 'does not update the data source configuration' do
      patch data_source_external_hmis_configuration_path(data_source), params: update_params
      expect(response).to have_http_status(:not_found)
      expect(saved_base_url).to be_nil
    end
  end

  context 'when the edit permission covers the data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, editor_role, collection)
    end

    it 'updates the data source configuration' do
      patch data_source_external_hmis_configuration_path(data_source), params: update_params
      expect(saved_base_url).to eq('https://changed.example')
    end
  end
end
