###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportThresholdsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }
  let(:project) { create(:hud_project, data_source: data_source) }
  let(:update_params) { { grda_warehouse_import_threshold: { pause_on_error_threshold: '1', error_count_min_threshold: '999' } } }

  before { sign_in user }

  def saved_threshold
    GrdaWarehouse::ImportThreshold.find_by(data_source_id: data_source.id)
  end

  context 'with view access to one project of the data source' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true), collection)
    end

    it 'shows the thresholds without edit controls' do
      get data_source_import_threshold_path(data_source)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Update Thresholds')
      expect(response.body).not_to include('Add Notification')
      expect(response.body).not_to include('Add Threshold Monitor')
    end

    it 'does not update the thresholds' do
      patch data_source_import_threshold_path(data_source), params: update_params
      expect(response).to redirect_to(root_path)
      expect(saved_threshold&.error_count_min_threshold).not_to eq(999)
    end
  end

  context 'with the edit permission only in a collection that does not include the data source' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true), collection)
      other_collection = create(:collection)
      other_collection.set_viewables({ data_sources: [create(:source_data_source).id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), other_collection)
    end

    it 'does not update the thresholds' do
      patch data_source_import_threshold_path(data_source), params: update_params
      expect(response).to have_http_status(:not_found)
      expect(saved_threshold&.error_count_min_threshold).not_to eq(999)
    end
  end

  context 'with the warehouse alerts permission' do
    let(:alerts_role) { create(:role, can_view_projects: true, can_edit_warehouse_alerts: true) }

    it 'updates the thresholds of a data source the user can view' do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, alerts_role, collection)

      patch data_source_import_threshold_path(data_source), params: update_params
      expect(saved_threshold.error_count_min_threshold).to eq(999)
    end

    it 'does not update the thresholds of a data source the user cannot view' do
      collection.set_viewables({ data_sources: [create(:source_data_source).id] })
      setup_access_control(user, alerts_role, collection)

      patch data_source_import_threshold_path(data_source), params: update_params
      expect(response).to have_http_status(:not_found)
      expect(saved_threshold&.error_count_min_threshold).not_to eq(999)
    end
  end

  context 'with the edit permission on the data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), collection)
    end

    it 'shows the edit controls' do
      get data_source_import_threshold_path(data_source)
      expect(response.body).to include('Update Thresholds')
      expect(response.body).to include('Add Notification')
      expect(response.body).to include('Add Threshold Monitor')
    end

    it 'updates the thresholds' do
      patch data_source_import_threshold_path(data_source), params: update_params
      expect(saved_threshold.error_count_min_threshold).to eq(999)
      expect(saved_threshold.pause_on_error_threshold).to be(true)
    end
  end
end
