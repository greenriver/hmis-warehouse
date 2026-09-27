###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe 'CoreDemographicsReport::WarehouseReports', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:core_report_definition) { create(:touch_point_report, url: 'core_demographics_report/warehouse_reports/core', name: 'Core Demographics') }
  let!(:demographic_summary_report_definition) { create(:touch_point_report, url: 'core_demographics_report/warehouse_reports/demographic_summary', name: 'Demographic Summary') }
  let!(:project) { create_project(project_type: 0) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [core_report_definition.id, demographic_summary_report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 2.months.ago.to_date)
    source.destination_client
  end

  let(:detail_filters) { { start: 1.year.ago.to_date, end: Date.current, project_ids: [project.id], require_service_during_range: 0 } }

  it 'lists every client in the core demographics detail when more clients than the preload miss threshold are in it' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    get details_core_demographics_report_warehouse_reports_core_index_path(key: "project_#{project.id}", filters: detail_filters)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client in the core demographics detail when more clients than the preload miss threshold are in it' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    get details_core_demographics_report_warehouse_reports_core_index_path(key: "project_#{project.id}", filters: detail_filters, format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end

  it 'exports every client in the demographic summary detail when more clients than the preload miss threshold are in it' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    get details_core_demographics_report_warehouse_reports_demographic_summary_index_path(key: "project_#{project.id}", filters: detail_filters, format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end

  after { GrdaWarehouse::Config.invalidate_cache }
end
