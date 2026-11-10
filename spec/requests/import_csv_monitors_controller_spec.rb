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

  # A user who can't see the data source gets a 404 from the load before any write check runs, so
  # these examples can't catch a write action missing from an only: list. The 'with view access to
  # one project of the data source' context does: it hits every write action and expects a redirect.
  # A not-found response drops the sign-in session, so each example makes one request.
  context 'with no rights' do
    it 'denies index' do
      get data_source_import_csv_monitors_path(data_source)
      expect(response).to redirect_to(root_path)
    end

    it 'denies create' do
      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(response).to have_http_status(:not_found)
      expect(created_monitor).to be_nil
    end
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

    it 'does not show the forms or create, update, or remove a monitor' do
      get new_data_source_import_csv_monitor_path(data_source)
      expect(response).to redirect_to(root_path)
      get edit_data_source_import_csv_monitor_path(data_source, monitor)
      expect(response).to redirect_to(root_path)

      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(response).to redirect_to(root_path)
      patch data_source_import_csv_monitor_path(data_source, monitor), params: update_params
      expect(response).to redirect_to(root_path)
      delete data_source_import_csv_monitor_path(data_source, monitor)
      expect(response).to redirect_to(root_path)

      expect(created_monitor).to be_nil
      expect(GrdaWarehouse::ImportCsvMonitor.exists?(monitor.id)).to be(true)
      expect(monitor.reload.count_increase_threshold).to eq(50)
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

    it 'creates and updates a monitor' do
      post data_source_import_csv_monitors_path(data_source), params: create_params
      expect(response).to redirect_to(data_source_import_threshold_path(data_source))
      expect(created_monitor).to be_present

      patch data_source_import_csv_monitor_path(data_source, monitor), params: update_params
      expect(monitor.reload.count_increase_threshold).to eq(99)
    end
  end
end
