###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboards::VeteransSubPop::VeteransController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true, can_view_clients: true) }
  let!(:report) { create(:touch_point_report, url: 'dashboards/veterans', name: 'Veterans') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night

  let(:report_month) { 1.month.ago.to_date.beginning_of_month }

  # `warehouse_partitioned_monthly_reports` is a legacy-STI-backed AR table normally populated
  # by a scheduled ETL (`Reporting::MonthlyReports::Base#populate!`). Task 1.6 confirmed that a
  # direct `.create!` on the concrete subclass lands a row the same way the ETL would, so the
  # dashboard's `enrolled_clients` scope chain can be exercised without running that pipeline.
  def create_monthly_report_row(client:)
    VeteransSubPop::Reporting::MonthlyReports::Veterans.create!(
      client_id: client.id,
      project_id: project.id,
      organization_id: organization.id,
      project_type: project.ProjectType,
      month: report_month.month,
      year: report_month.year,
      mid_month: report_month + 14.days,
      enrolled: true,
      active: true,
      entered: true,
      head_of_household: 1,
      calculated_at: Time.current,
    )
  end

  let!(:restricted_report_row) { create_monthly_report_row(client: restricted_destination_client) }
  let!(:open_report_row) { create_monthly_report_row(client: open_destination_client) }

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback — without this, an earlier example's
  # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  def request_xlsx
    get dashboards_veterans_path(
      format: :xlsx,
      filters: { start: report_month.beginning_of_month.to_s, end: report_month.end_of_month.to_s },
    )
  end

  def rendered_workbook
    excel_file = Tempfile.new(['dashboards_veterans', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  def row_for(client)
    sheet = rendered_workbook.sheet(0)
    (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == client.id }
  end

  it 'redacts the restricted client name and shows the unrestricted client name when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    request_xlsx

    expect(response).to have_http_status(:success)
    restricted_row = row_for(restricted_destination_client)
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')

    open_row = row_for(open_destination_client)
    expect(open_row[1]).to eq('Open')
    expect(open_row[2]).to eq('Client')
  end

  it 'redacts both clients names when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)

    request_xlsx

    expect(response).to have_http_status(:success)
    restricted_row = row_for(restricted_destination_client)
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')

    open_row = row_for(open_destination_client)
    expect(open_row[1]).to eq('Name Redacted')
    expect(open_row[2]).to eq('Name Redacted')
  end
end
