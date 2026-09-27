###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'PerformanceMetrics::WarehouseReports::ReportsController#details', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'performance_metrics/warehouse_reports/reports', name: 'Performance Metrics') }
  let!(:project) { create_project(project_type: 1) }
  let!(:pm_report) { PerformanceMetrics::Report.create!(user_id: user.id) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    PerformanceMetrics::Client.create!(
      report_id: pm_report.id,
      client_id: source.destination_client.id,
      first_name: source.FirstName,
      last_name: source.LastName,
      include_in_current_period: true,
    )
  end

  it 'lists every client when more clients than the preload miss threshold were served' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get details_performance_metrics_warehouse_reports_report_path(pm_report, key: :clients_served, sub_key: :clients_served)

    expect(response).to have_http_status(:ok)
    extra.each { |row| expect(response.body).to include(row.first_name) }
  end
end
