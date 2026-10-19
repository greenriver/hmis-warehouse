###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Confidential project names for role-based users in the Project Data Quality report', type: :request do
  include LegacyProjectNamesSetup

  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source, OrganizationName: 'Distinct Org Name') }
  let!(:project) do
    create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Distinct Project Name', confidential: true)
  end
  let!(:other_project) do
    create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Open Door Shelter')
  end
  let(:placeholder) { GrdaWarehouse::Hud::Project.confidential_project_name }
  let(:reporting_permissions) do
    { can_view_assigned_reports: true, can_view_projects: true, can_report_on_confidential_projects: true, can_view_clients: true }
  end
  let(:names_permissions) { reporting_permissions.merge(can_view_confidential_project_names: true) }

  before do
    Collection.maintain_system_groups
    GrdaWarehouse::Grades::Base.install_default_grades!
  end

  describe 'the project report page' do
    let(:stored_report) { { agency_name: organization.OrganizationName, project_name: project.ProjectName } }

    def open_report_as(user)
      report = create(:data_quality_report_version_five, project: project, requestor_id: user.id, report: stored_report)
      sign_in(user)
      get project_data_quality_report_path(project, report)
    end

    it 'shows the confidential names to a requestor whose role has the names permission and whose access group has the project' do
      open_report_as(create_legacy_user(names_permissions, [report_definition, project]))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Distinct Project Name')
      expect(response.body).to include('Distinct Org Name')
    end

    it 'does not open the report for a requestor whose access group has a different project' do
      user = create_legacy_user(names_permissions, [report_definition, other_project])
      open_report_as(user)

      expect(response).to redirect_to(user.my_root_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end

    it 'masks the names for a project contact whose access group has a different project' do
      user = create_legacy_user(names_permissions, [report_definition, other_project])
      create(:grda_warehouse_contact_project, entity: project, user: user)
      open_report_as(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(placeholder)
      expect(response.body).not_to include('Distinct Project Name')
      expect(response.body).not_to include('Distinct Org Name')
    end

    it 'does not open the report for a requestor whose role has the names permission but not project view' do
      user = create_legacy_user({ can_view_assigned_reports: true, can_view_confidential_project_names: true }, [report_definition, project])
      open_report_as(user)

      expect(response).to redirect_to(user.my_root_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end

    it 'masks the names for a requestor whose role has project view but not the names permission' do
      open_report_as(create_legacy_user(reporting_permissions, [report_definition, project]))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(placeholder)
      expect(response.body).not_to include('Distinct Project Name')
      expect(response.body).not_to include('Distinct Org Name')
    end
  end

  describe 'support rows for a group with a confidential project' do
    let!(:project_group) { create(:project_group, projects: [project, other_project]) }
    let(:support_data) do
      {
        headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN', 'Project ID', 'Project'],
        counts: [
          [101, 'Casey', 'Example', '1980-01-01', '111223333', other_project.id, 'Open Door Shelter'],
          [102, 'Dana', 'Hidden', '1975-02-02', '444556666', project.id, 'Distinct Project Name'],
        ],
        title: 'Clients',
      }
    end

    before do
      allow_any_instance_of(GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive).to receive(:support_for).and_return(support_data)
    end

    def project_cells_as(user)
      report = create(:data_quality_report_version_five, project: nil, project_group: project_group, requestor_id: user.id)
      sign_in(user)
      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')
      Nokogiri::HTML(response.body).css('table.table-hover tbody td').map { |td| td.text.strip }
    end

    it 'shows the confidential project name to a user whose role has the names permission and whose access group has the project' do
      cells = project_cells_as(create_legacy_user(names_permissions, [report_definition, project_group, project, other_project]))

      expect(cells).to include('Open Door Shelter', 'Distinct Project Name')
      expect(cells).not_to include(placeholder)
    end

    it 'masks the confidential project name for a user whose role lacks the names permission' do
      cells = project_cells_as(create_legacy_user(reporting_permissions, [report_definition, project_group, project, other_project]))

      expect(cells).to include('Open Door Shelter', placeholder)
      expect(cells).not_to include('Distinct Project Name')
    end
  end

  describe 'the queue page' do
    def listed_as(user)
      sign_in(user)
      get warehouse_reports_project_data_quality_path, params: { filters: { project_ids: [project.id, other_project.id] } }
    end

    it 'lists the confidential project for a user whose role has the names permission and whose access group has the project' do
      listed_as(create_legacy_user(names_permissions, [report_definition, project, other_project]))

      expect(response.body).to include("project[#{project.id}]")
      expect(response.body).to include("project[#{other_project.id}]")
      expect(response.body).to include('Distinct Project Name')
    end

    it 'does not list the confidential project for a user whose access group lacks it' do
      listed_as(create_legacy_user(names_permissions, [report_definition, other_project]))

      expect(response.body).not_to include("project[#{project.id}]")
      expect(response.body).to include("project[#{other_project.id}]")
      expect(response.body).not_to include('Distinct Project Name')
    end
  end
end
