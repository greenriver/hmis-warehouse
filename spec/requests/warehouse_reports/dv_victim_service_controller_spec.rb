###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::DvVictimServiceController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'warehouse_reports/dv_victim_service', name: 'DV Victim Service') }
  let!(:project) { create_project(project_type: 3) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    enrollment = create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    create_health_and_dv(enrollment: enrollment, information_date: 1.week.ago.to_date, currently_fleeing: 1)
    source
  end

  it 'lists every client when more clients than the preload miss threshold are currently fleeing' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get warehouse_reports_dv_victim_service_index_path(filters: { start: 1.month.ago.to_date, end: Date.current })

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
