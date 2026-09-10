###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MaYyaReport::WarehouseReports::Reports#details', type: :request do
  let(:data_source) { create(:data_source_fixed_id) }
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: data_source) }

  let(:report_definition) do
    # Must match this controller's index route — WarehouseReportAuthorization#related_report derives
    # that route from url_for(action: :index) and looks up a ReportDefinition by it to authorize the request.
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'ma_yya_report/warehouse_reports/reports',
      name: 'MA YYA Report',
      report_group: 'Reports',
      description: 'MA YYA Report',
    )
  end
  let(:access_group) { create(:access_group) }
  let(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_clients: true,
      can_view_client_name: true,
    )
  end
  let(:user) do
    user = create(:user)
    role.add(user)
    access_group.add(user)
    access_group.add_viewable(report_definition)
    access_group.add_viewable(project)
    user
  end

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:report) { MaYyaReport::Report.create!(user_id: user.id) }
  let!(:restricted_report_client) { MaYyaReport::Client.create!(report: report, client_id: restricted_destination_client.id, project: project, age: 20) }
  let!(:open_report_client) { MaYyaReport::Client.create!(report: report, client_id: open_destination_client.id, project: project, age: 21) }
  let!(:report_cell) { report.report_cells.create!(name: 'A1a') }
  let!(:restricted_universe_member) do
    SimpleReports::UniverseMember.create!(
      report_cell: report_cell,
      client_id: restricted_destination_client.id,
      first_name: 'Restricted',
      last_name: 'Client',
      universe_membership: restricted_report_client,
    )
  end
  let!(:open_universe_member) do
    SimpleReports::UniverseMember.create!(
      report_cell: report_cell,
      client_id: open_destination_client.id,
      first_name: 'Open',
      last_name: 'Doe',
      universe_membership: open_report_client,
    )
  end

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'redacts the restricted client and leaves the unrestricted client intact in the rendered table' do
    get details_ma_yya_report_warehouse_reports_report_path(report, cell: 'A1a')

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Redacted')
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Open')
  end
end
