###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'SystemPathways::WarehouseReports::ReportsController#details', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'system_pathways/warehouse_reports/reports', name: 'System Pathways') }
  let!(:project) { create_project(project_type: 1) }
  let!(:sp_report) { SystemPathways::Report.create!(user_id: user.id) }

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
    destination = source.destination_client
    sp_client = SystemPathways::Client.create!(report_id: sp_report.id, client_id: destination.id, first_name: source.FirstName, last_name: source.LastName)
    SystemPathways::Enrollment.create!(report_id: sp_report.id, client_id: destination.id, project_id: project.id, enrollment_id: index + 1, project_type: 1, final_enrollment: true)
    sp_client
  end

  it 'lists every client when more clients than the preload miss threshold were served' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get details_system_pathways_warehouse_reports_report_path(sp_report, node: 'Served by Homeless System')

    expect(response).to have_http_status(:ok)
    extra.each { |row| expect(response.body).to include(row.first_name) }
  end
end
