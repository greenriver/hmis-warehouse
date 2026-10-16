###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::DataQualityReportPolicy, type: :model do
  let(:data_source) { create :grda_warehouse_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
  let(:other_project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
  let(:project_group) { create :project_group, projects: [project] }
  let(:other_project_group) { create :project_group, projects: [other_project] }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end
  let(:project_report) { create :data_quality_report_version_five, project: project }
  let(:group_report) { create :data_quality_report_version_five, project: nil, project_group: project_group }
  let(:reporting_role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }

  it 'raises for a resource that is not a data quality report' do
    user = create(:acl_user)

    expect { described_class.new(context: user.policy_context, resource: project) }.to raise_error(ArgumentError)
  end

  context 'with access control permissions' do
    let(:user) { create(:acl_user) }

    def grant(role, collection)
      user_group = create(:user_group)
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    def collection_with(viewables)
      create(:collection).tap { |collection| collection.set_viewables(viewables) }
    end

    it 'allows a project report when the collection includes the report definition and the project' do
      grant(reporting_role, collection_with(reports: [report_definition.id], projects: [project.id]))

      expect(user.policy_for(project_report).can_view?).to be true
    end

    it 'denies a project report when the collection includes only a different project' do
      grant(reporting_role, collection_with(reports: [report_definition.id], projects: [other_project.id]))

      expect(user.policy_for(project_report).can_view?).to be false
    end

    it 'denies a project report when the collection includes the project but not the report definition' do
      grant(reporting_role, collection_with(projects: [project.id]))

      expect(user.policy_for(project_report).can_view?).to be false
    end

    it 'allows a project group report when the collection includes the report definition and the group' do
      grant(reporting_role, collection_with(reports: [report_definition.id], project_groups: [project_group.id]))

      expect(user.policy_for(group_report).can_view?).to be true
    end

    it 'denies a project group report when the collection includes only a different group' do
      grant(reporting_role, collection_with(reports: [report_definition.id], project_groups: [other_project_group.id]))

      expect(user.policy_for(group_report).can_view?).to be false
    end

    it 'denies a project group report when the collection includes the group projects but not the group' do
      grant(reporting_role, collection_with(reports: [report_definition.id], projects: [project.id]))

      expect(user.policy_for(group_report).can_view?).to be false
    end
  end

  context 'with legacy role permissions' do
    let(:user) { create(:user) }
    let(:access_group) { create(:access_group) }

    before do
      access_group.add(user)
      reporting_role.add(user)
      access_group.add_viewable(report_definition)
    end

    it 'allows a project report when an access group includes the project' do
      access_group.add_viewable(project)

      expect(user.policy_for(project_report).can_view?).to be true
    end

    it 'denies a project report when the access group includes only a different project' do
      access_group.add_viewable(other_project)

      expect(user.policy_for(project_report).can_view?).to be false
    end

    it 'allows a project group report when an access group includes the group' do
      access_group.add_viewable(project_group)

      expect(user.policy_for(group_report).can_view?).to be true
    end

    it 'denies a project group report when the access group includes only a different group' do
      access_group.add_viewable(other_project_group)

      expect(user.policy_for(group_report).can_view?).to be false
    end
  end
end
