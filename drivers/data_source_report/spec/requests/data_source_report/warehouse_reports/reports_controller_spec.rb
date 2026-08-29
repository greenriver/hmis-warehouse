###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSourceReport::WarehouseReports::ReportsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) { create(:data_source_report) }
  let!(:data_source) { create(:source_data_source, name: 'Stale Vendor') }

  before do
    collection.set_viewables(reports: [report_definition.id], data_sources: [data_source.id], projects: [])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'shows the stalled-import label for a data source whose most recent import is stale' do
      create(:grda_warehouse_hmis_import_config, data_source: data_source, file_count: 1)
      create(:grda_warehouse_upload, data_source: data_source, user: User.system_user, percent_complete: 100, completed_at: 30.hours.ago)
      GrdaWarehouse::ImportLog.create!(data_source: data_source, completed_at: 30.hours.ago)

      get data_source_report_warehouse_reports_reports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('same file since:')
    end

    it 'shows no stalled-import label for a data source with no import history' do
      get data_source_report_warehouse_reports_reports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('same file since:')
    end
  end
end
