###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'CePerformance::WarehouseReports::ReportsController#clients', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'ce_performance/warehouse_reports/reports', name: 'CE Performance') }
  let!(:project) { create_project(project_type: 1) }
  let!(:ce_report) { create(:simple_reports_report_instance, type: 'CePerformance::Report', user_id: user.id) }
  let!(:result) { CePerformance::Results::ClientsScreened.create!(report_id: ce_report.id, period: 'reporting') }

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
    CePerformance::Client.create!(
      report_id: ce_report.id,
      client_id: source.id,
      destination_client_id: source.destination_client.id,
      period: 'reporting',
      q5a_b1: true,
      head_of_household: true,
      prevention_tool_score: 1,
      first_name: source.FirstName,
      last_name: source.LastName,
    )
  end

  it 'lists every client when more clients than the preload miss threshold were screened' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get clients_ce_performance_warehouse_reports_report_path(ce_report, key: 'CePerformance::Results::ClientsScreened', category_name: 'Participation', period: 'reporting')

    expect(response).to have_http_status(:ok)
    extra.each { |row| expect(response.body).to include(row.first_name) }
  end

  it 'exports every client when more clients than the preload miss threshold were screened' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get clients_ce_performance_warehouse_reports_report_path(ce_report, key: 'CePerformance::Results::ClientsScreened', category_name: 'Participation', period: 'reporting', format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:first_name))
  end
end
