###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::AnomaliesController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'warehouse_reports/anomalies', name: 'Anomalies') }
  let!(:project) { create_project(project_type: 1) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index, status:)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    GrdaWarehouse::Anomaly.create!(client: source.destination_client, status: status, submitted_by: user.id, description: "Anomaly #{index}")
    source.destination_client
  end

  it 'lists every client across all statuses when more clients than the preload miss threshold have anomalies' do
    statuses = ['new', 'unresolved', 'resolved']
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i, status: statuses[i % statuses.size]) }

    get warehouse_reports_anomalies_path

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
