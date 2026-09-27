###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::Cas::HealthPrioritizationController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'warehouse_reports/cas/health_prioritization', name: 'Health Prioritization') }
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
    enrollment = create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    create_bed_night_service(enrollment: enrollment, date: 1.week.ago.to_date)
    source.destination_client
  end

  def build_preload_clients
    clients = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    clients
  end

  it 'lists every client when more clients than the preload miss threshold were served' do
    extra = build_preload_clients

    get warehouse_reports_cas_health_prioritization_index_path

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client when more clients than the preload miss threshold were served' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = build_preload_clients

    get warehouse_reports_cas_health_prioritization_index_path(format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map { |client| "#{client.FirstName} #{client.LastName}" })
  end
end
