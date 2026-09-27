###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'IncomeBenefitsReport::WarehouseReports::ReportController#details', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'income_benefits_report/warehouse_reports/report', name: 'Income and Benefits') }
  let!(:project) { create_project(project_type: 1) }
  let!(:ib_report) do
    IncomeBenefitsReport::Report.create!(
      user_id: user.id,
      report_date_range: Date.current.beginning_of_year..Date.current.end_of_year,
      comparison_date_range: 1.year.ago.beginning_of_year.to_date..1.year.ago.end_of_year.to_date,
    )
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage', DOB: '1990-06-15'.to_date)
  end

  def stub_detail_rows(clients)
    rows = clients.map { |c| [c.id, c.FirstName, c.LastName, c.DOB, nil] }
    allow_any_instance_of(IncomeBenefitsReport::Report).to receive(:columns_for).and_return(rows)
    allow_any_instance_of(IncomeBenefitsReport::Report).to receive(:columns_for_export).and_return(rows)
    allow_any_instance_of(IncomeBenefitsReport::Report).to receive(:support_title).and_return('Preload coverage')
  end

  it 'lists every client when more clients than the preload miss threshold are in the detail table' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    stub_detail_rows(extra)

    get details_income_benefits_report_warehouse_reports_report_path(ib_report, key: 'preload')

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client when more clients than the preload miss threshold are in the detail table' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    stub_detail_rows(extra)

    get details_income_benefits_report_warehouse_reports_report_path(ib_report, key: 'preload', format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end
end
