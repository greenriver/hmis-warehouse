###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'HmisDataQualityTool::WarehouseReports::ReportsController#items and #by_client', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'hmis_data_quality_tool/warehouse_reports/reports', name: 'HMIS Data Quality Tool') }
  let!(:project) { create_project(project_type: 1) }
  let!(:dq_report) { HmisDataQualityTool::Report.create!(user_id: user.id, report_name: 'HMIS Data Quality Tool', options: {}, question_names: []) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    HmisDataQualityTool::Client.create!(
      report_id: dq_report.id,
      client_id: source.id,
      destination_client_id: source.destination_client.id,
      personal_id: source.PersonalID,
      data_source_id: source.data_source_id,
      first_name: source.FirstName,
      last_name: source.LastName,
      ch_at_most_recent_entry: true,
    )
  end

  it 'lists every client in a drilldown when more clients than the preload miss threshold are in it' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get items_hmis_data_quality_tool_warehouse_reports_report_path(dq_report, key: 'client_ch_most_recent')

    expect(response).to have_http_status(:ok)
    extra.each { |row| expect(response.body).to include(row.first_name) }
  end
end
