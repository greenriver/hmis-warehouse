###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'ClientLocationHistory::WarehouseReports::ClientLocationHistoryController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'client_location_history/warehouse_reports/client_location_history', name: 'Client Location History') }
  let!(:project) { create_project(project_type: 1) }

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
    create(:clh_location, client_id: source.destination_client.id, located_on: 1.month.ago.to_date)
    source.destination_client
  end

  it 'lists every client on the map when more clients than the preload miss threshold have locations' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get client_location_history_warehouse_reports_client_location_history_index_path(filters: { start: 6.months.ago.to_date, end: Date.current })

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
