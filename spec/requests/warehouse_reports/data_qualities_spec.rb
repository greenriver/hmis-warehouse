###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::Project::DataQualitiesController, type: :request do
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
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Reportable Project') }
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Other Collection Project') }
  let!(:project_group) { create(:project_group, projects: [project]) }
  let!(:other_project_group) { create(:project_group, projects: [other_project]) }
  let!(:reporting_role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }

  before do
    Collection.maintain_system_groups
    sign_in(user)
  end

  context 'with the report definition and some subjects in one collection and other subjects in another' do
    before do
      report_collection = create(:collection)
      report_collection.set_viewables({ reports: [report_definition.id], projects: [project.id], project_groups: [project_group.id] })
      setup_access_control(user, reporting_role, report_collection)
      other_collection = create(:collection)
      other_collection.set_viewables({ projects: [other_project.id], project_groups: [other_project_group.id] })
      setup_access_control(user, reporting_role, other_collection)
    end

    def queue(project_ids: [], project_group_ids: [])
      post warehouse_reports_project_data_quality_path, params: {
        project_data_quality: { start: '2025-10-01', end: '2026-09-30', generate: '1' },
        project: project_ids.to_h { |id| [id.to_s, '1'] },
        project_group: project_group_ids.to_h { |id| [id.to_s, '1'] },
      }
    end

    def queued_rows
      GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive.pluck(:project_id, :project_group_id, :requestor_id)
    end

    it 'queues reports for a project and a group in the same collection as the report definition' do
      queue(project_ids: [project.id], project_group_ids: [project_group.id])

      expect(queued_rows).to contain_exactly([project.id, nil, user.id], [nil, project_group.id, user.id])
    end

    it 'does not queue a project or group that is only in a different collection' do
      queue(project_ids: [project.id, other_project.id], project_group_ids: [other_project_group.id])

      expect(queued_rows).to contain_exactly([project.id, nil, user.id])
    end

    it 'lists only same-collection projects on the selection page' do
      get warehouse_reports_project_data_quality_path, params: { filters: { project_ids: [project.id, other_project.id] } }

      expect(response.body).to include("project[#{project.id}]")
      expect(response.body).not_to include("project[#{other_project.id}]")
    end
  end

  describe 'history' do
    let!(:other_user) { create(:user) }

    def report_links
      Nokogiri::HTML(response.body).css('table tbody a').map { |a| a['href'] }
    end

    it 'lists the report on the contact project and not the unrelated report' do
      contact_collection = create(:collection)
      contact_collection.set_viewables({ reports: [report_definition.id] })
      setup_access_control(user, create(:role, can_view_assigned_reports: true), contact_collection)
      create(:grda_warehouse_contact_project, entity: project, user: user)
      contact_report = create(:data_quality_report_version_five, project: project, requestor_id: other_user.id, started_at: 1.day.ago)
      create(:data_quality_report_version_five, project: other_project, requestor_id: other_user.id, started_at: 1.day.ago)

      get history_warehouse_reports_project_data_quality_path

      expect(report_links).to contain_exactly(project_data_quality_report_path(project_id: project.id, id: contact_report.id))
    end

    it 'lists only the requestor own report for a user without can_view_all_reports' do
      report_collection = create(:collection)
      report_collection.set_viewables({ reports: [report_definition.id], projects: [project.id, other_project.id] })
      setup_access_control(user, reporting_role, report_collection)
      own_report = create(:data_quality_report_version_five, project: project, requestor_id: user.id, started_at: 1.day.ago)
      create(:data_quality_report_version_five, project: other_project, requestor_id: other_user.id, started_at: 1.day.ago)

      get history_warehouse_reports_project_data_quality_path

      expect(report_links).to contain_exactly(project_data_quality_report_path(project_id: project.id, id: own_report.id))
    end
  end
end
