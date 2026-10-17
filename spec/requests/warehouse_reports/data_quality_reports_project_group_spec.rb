###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportsProjectGroupController', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_group) { create(:project_group, projects: [project]) }
  let!(:other_project_group) { create(:project_group, projects: [other_project]) }
  let!(:report) { create(:data_quality_report_version_five, project: nil, project_group: project_group, requestor_id: user.id) }
  let!(:other_report) { create(:data_quality_report_version_five, project: nil, project_group: other_project_group) }
  let(:support_data) do
    {
      headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN'],
      counts: [[1, 'Casey', 'Example', '1980-01-01', '123456789']],
      title: 'Clients',
    }
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], project_groups: [project_group.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    allow_any_instance_of(GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive).to receive(:support_for).and_return(support_data)
    sign_in(user)
  end

  it 'renders support rows for a report on a group in the user collections' do
    get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Casey')
    expect(response.body).to include(destination_source_client_path(id: 1))
  end

  context 'when the user cannot view clients' do
    let!(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }

    it 'redirects support without rendering rows' do
      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

      expect(response).to redirect_to(user.my_root_path)
      expect(response.body).not_to include('Casey')
    end

    it 'renders show for the report' do
      get project_group_data_quality_report_path(project_group, report)

      expect(response).to have_http_status(:ok)
    end
  end

  it 'redirects support for a report on a group outside the user collections without rendering rows' do
    get support_project_group_data_quality_report_path(other_project_group, other_report, individual: true, method: 'test')

    expect(response).to redirect_to(user.my_root_path)
    expect(flash[:alert]).to be_present
    expect(response.body).not_to include('Casey')
  end

  it 'returns not found when the report id belongs to a different group' do
    get support_project_group_data_quality_report_path(project_group, other_report, individual: true, method: 'test')

    expect(response).to have_http_status(:not_found)
  end

  it 'allows index for a group in the user collections' do
    get project_group_data_quality_reports_path(project_group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(project_group.name)
  end

  it 'redirects index for a group outside the user collections' do
    get project_group_data_quality_reports_path(other_project_group)

    expect(response).to redirect_to(user.my_root_path)
  end

  it 'renders show for a report on a group in the user collections' do
    get project_group_data_quality_report_path(project_group, report)

    expect(response).to have_http_status(:ok)
  end

  it 'returns the report answers for a group in the user collections' do
    report.update!(report: { 'total_clients' => 'Viewable group answer' })

    get answers_project_group_data_quality_report_path(project_group, report)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq('total_clients' => 'Viewable group answer')
  end

  it 'redirects answers for a report on a group outside the user collections without returning the report' do
    other_report.update!(report: { 'total_clients' => 'Hidden group answer' })

    get answers_project_group_data_quality_report_path(other_project_group, other_report)

    expect(response).to redirect_to(user.my_root_path)
    expect(response.body).not_to include('Hidden group answer')
  end

  it 'redirects a logged-out request for show to sign in' do
    sign_out(user)

    get project_group_data_quality_report_path(project_group, report)

    expect(response).to redirect_to(new_user_session_path)
  end

  it 'does not route the former notification path' do
    get "/notifications/abc/project_groups/#{project_group.id}/data_quality_reports/#{report.id}"

    expect(response).to have_http_status(:not_found)
  end
end
