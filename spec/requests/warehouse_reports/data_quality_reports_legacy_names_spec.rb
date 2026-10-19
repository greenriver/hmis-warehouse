###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Legacy project data quality report names', type: :request do
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
  let(:user) { create(:acl_user) }
  let(:stored_report) do
    {
      agency_name: organization.OrganizationName,
      project_name: project.ProjectName,
    }
  end

  before do
    Collection.maintain_system_groups
    GrdaWarehouse::Grades::Base.install_default_grades!
    sign_in(user)
  end

  def grant(role_attributes, viewables)
    collection = create(:collection)
    collection.set_viewables({ reports: [report_definition.id] }.merge(viewables))
    setup_access_control(user, create(:role, **role_attributes), collection)
    user.clear_memery_cache!
  end

  shared_examples 'a legacy report page' do |factory|
    let!(:report) { create(factory, project: project, requestor_id: user.id, report: stored_report) }

    context 'when the user is a contact without project access' do
      before do
        grant({ can_view_assigned_reports: true }, {})
        create(:grda_warehouse_contact_project, entity: project, user: user)
      end

      it 'shows neither the project nor the organization name' do
        get project_data_quality_report_path(project, report)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(GrdaWarehouse::Hud::Project.confidential_project_name)
        expect(response.body).not_to include('Distinct Project Name')
        expect(response.body).not_to include('Distinct Org Name')
      end
    end

    context 'when the user can view confidential names on the project' do
      before do
        grant(
          { can_view_assigned_reports: true, can_view_projects: true, can_report_on_confidential_projects: true, can_view_confidential_project_names: true },
          { projects: [project.id] },
        )
      end

      it 'shows the stored-name cells using the live names' do
        get project_data_quality_report_path(project, report)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Distinct Project Name')
        expect(response.body).to include('Distinct Org Name')
      end
    end
  end

  context 'with a version one report' do
    it_behaves_like 'a legacy report page', :data_quality_report_version_one
  end

  context 'with a version two report' do
    it_behaves_like 'a legacy report page', :data_quality_report_version_two
  end
end
