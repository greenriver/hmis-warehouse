###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD report Excel download', type: :request do
  let(:user) { create(:acl_user) }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:chosen_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 2, ProjectName: 'Chosen Project') }
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 2, ProjectName: 'Other Project') }
  let(:report) do
    create(
      :hud_reports_report_instance,
      user: user,
      report_name: HudApr::Generators::Apr::Fy2026::Generator.title,
      options: {
        'start' => '2025-10-01',
        'end' => '2026-09-30',
        'report_version' => 'fy2026',
        'project_ids' => [chosen_project.id],
        'coc_codes' => ['XX-500'],
      },
    )
  end

  before do
    [chosen_project, other_project].each do |project|
      create(:hud_project_coc, ProjectID: project.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-500')
    end
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    definition = GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: 'hud_reports/aprs')
    collection = create(:collection)
    collection.set_viewables(reports: [definition.id], projects: [chosen_project.id, other_project.id])
    setup_access_control(user, create(:role, can_view_assigned_reports: true), collection)
    sign_in(user)
  end

  def summary_rows
    file = Tempfile.new(['apr', '.xlsx'])
    file.binmode
    file.write(response.body)
    file.close
    sheet = Roo::Excelx.new(file.path).sheet('Summary')
    (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
  ensure
    file&.unlink
  end

  it 'lists only the chosen project, not every project in the chosen CoC' do
    get download_hud_reports_apr_path(report, format: :xlsx)

    expect(response).to have_http_status(:ok)
    projects = summary_rows.find { |(label, _)| label == 'Projects' }&.last
    expect(projects).to eq('Chosen Project')
  end
end
