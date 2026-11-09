###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportCsvMonitorsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }
  let(:project) { create(:hud_project, data_source: data_source) }
  let!(:monitor) { create(:grda_warehouse_import_csv_monitor, data_source: data_source, csv_file_name: 'Client.csv', count_increase_threshold: 50) }
  let(:create_params) { { grda_warehouse_import_csv_monitor: { csv_file_name: 'Enrollment.csv', count_increase_threshold: '10', active: '1' } } }
  let(:update_params) { { grda_warehouse_import_csv_monitor: { count_increase_threshold: '99' } } }

  before { sign_in user }

  def created_monitor
    GrdaWarehouse::ImportCsvMonitor.find_by(data_source_id: data_source.id, csv_file_name: 'Enrollment.csv')
  end

  context 'with view access to one project of the data source' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true), collection)
    end

    it 'redirects the index to the thresholds page' do
      get data_source_import_csv_monitors_path(data_source)
      expect(response).to redirect_to(data_source_import_threshold_path(data_source))
    end

    it 'does not create a monitor' do
      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(response).to redirect_to(root_path)
      expect(created_monitor).to be_nil
    end

    it 'does not update or remove a monitor' do
      patch data_source_import_csv_monitor_path(data_source, monitor), params: update_params
      expect(response).to redirect_to(root_path)
      delete data_source_import_csv_monitor_path(data_source, monitor)
      expect(response).to redirect_to(root_path)
      expect(monitor.reload.count_increase_threshold).to eq(50)
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

    it 'does not create a monitor' do
      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(response).to have_http_status(:not_found)
      expect(created_monitor).to be_nil
    end

    it 'does not remove a monitor' do
      delete data_source_import_csv_monitor_path(data_source, monitor)
      expect(response).to have_http_status(:not_found)
      expect(GrdaWarehouse::ImportCsvMonitor.exists?(monitor.id)).to be(true)
    end
  end

  context 'with the warehouse alerts permission and view access to one project' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_warehouse_alerts: true), collection)
    end

    it 'creates a monitor' do
      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(created_monitor).to be_present
    end
  end

  context 'with the edit permission on the data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), collection)
    end

    it 'creates a monitor' do
      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(response).to redirect_to(data_source_import_threshold_path(data_source))
      expect(created_monitor).to be_present
    end

    it 'updates a monitor' do
      patch data_source_import_csv_monitor_path(data_source, monitor), params: update_params
      expect(monitor.reload.count_increase_threshold).to eq(99)
    end
  end
end
