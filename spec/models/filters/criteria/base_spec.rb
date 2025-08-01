# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::Base do
  include_context 'filter criteria setup'
  include ArelHelper

  let(:filter) { ::Filters::FilterBase.new(user_id: user.id) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create test data for different scenarios
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:project_1) { create_project(organization_id: organization.organization_id, ProjectName: 'Project Alpha') }
  let!(:project_2) { create_project(organization_id: organization.organization_id, ProjectName: 'Project Beta') }
  let!(:project_3) { create_project(organization_id: organization.organization_id, ProjectName: 'Project Gamma') }

  let!(:confidential_organization) { create(:hud_organization, data_source_id: data_source.id, confidential: true) }
  let!(:confidential_project) { create_project(organization_id: confidential_organization.organization_id, ProjectName: 'Confidential Project') }

  let!(:client_1) { create(:hud_client, data_source_id: data_source.id) }
  let!(:client_2) { create(:hud_client, data_source_id: data_source.id) }
  let!(:client_3) { create(:hud_client, data_source_id: data_source.id) }
  let!(:client_4) { create(:hud_client, data_source_id: data_source.id) }

  let!(:enrollment_1) { create_enrollment_for_client(client_1, project_id: project_1.ProjectID) }
  let!(:enrollment_2) { create_enrollment_for_client(client_2, project_id: project_2.ProjectID) }
  let!(:enrollment_3) { create_enrollment_for_client(client_3, project_id: project_3.ProjectID) }
  let!(:enrollment_4) { create_enrollment_for_client(client_4, project_id: confidential_project.ProjectID) }

  describe '#viewable_project_scope' do
    context 'when user has can_view_assigned_reports permission' do
      before do
        # Give user access to all projects for reporting
        setup_access_control(user, role, Collection.system_collection(:data_sources))
      end

      it 'returns projects viewable by user with can_view_assigned_reports permission' do
        scope = criteria.viewable_project_scope
        expect(scope).to be_a(ActiveRecord::Relation)
        expect(scope.model).to eq(GrdaWarehouse::Hud::Project)
      end

      it 'includes all non-confidential projects in the organization' do
        scope = criteria.viewable_project_scope
        project_ids = scope.pluck(:id)

        expect(project_ids).to include(project_1.id, project_2.id, project_3.id)
      end

      it 'excludes confidential projects when user cannot report on confidential projects' do
        # Remove confidential reporting permission
        role.update!(can_report_on_confidential_projects: false)

        scope = criteria.viewable_project_scope
        project_ids = scope.pluck(:id)

        expect(project_ids).not_to include(confidential_project.id)
      end

      it 'includes confidential projects when user can report on confidential projects' do
        # Add confidential reporting permission
        role.update!(can_report_on_confidential_projects: true)

        scope = criteria.viewable_project_scope
        project_ids = scope.pluck(:id)

        # Verify confidential projects are included as well as non-confidential projects
        expect(project_ids).to include(confidential_project.id, project_1.id, project_2.id, project_3.id)
      end
    end

    context 'when user has limited project access' do
      let(:limited_role) { create(:role, can_view_assigned_reports: true, can_report_on_confidential_projects: false) }
      let(:limited_user) { create(:acl_user) }
      let(:limited_filter) { ::Filters::FilterBase.new(user_id: limited_user.id) }
      let(:limited_criteria) { described_class.new(input: limited_filter, config: config) }

      before do
        # Create a collection with only specific projects
        limited_collection = create(:collection)
        limited_collection.set_viewables({ projects: [project_1.id, project_2.id] })
        setup_access_control(limited_user, limited_role, limited_collection)
      end

      it 'returns only projects the user has access to' do
        scope = limited_criteria.viewable_project_scope
        project_ids = scope.pluck(:id)

        expect(project_ids).to contain_exactly(project_1.id, project_2.id)
      end
    end

    context 'when user does not have can_view_assigned_reports permission' do
      let(:no_report_role) { create(:role, can_view_assigned_reports: false) }
      let(:no_report_user) { create(:acl_user) }
      let(:no_report_filter) { ::Filters::FilterBase.new(user_id: no_report_user.id) }
      let(:no_report_criteria) { described_class.new(input: no_report_filter, config: config) }

      before do
        # Create a collection with specific projects but user has no report permission
        specific_collection = create(:collection)
        specific_collection.set_viewables({ projects: [project_1.id, project_2.id] })
        setup_access_control(no_report_user, no_report_role, specific_collection)
      end

      it 'returns no projects' do
        scope = no_report_criteria.viewable_project_scope
        expect(scope).to be_empty
      end
    end
  end

  describe 'separation between projects and reports' do
    let(:report_role) { create(:role, can_view_assigned_reports: true, can_view_projects: false) }
    let(:project_role) { create(:role, can_view_projects: true, can_view_assigned_reports: false) }
    let(:report_user) { create(:acl_user) }
    let(:project_user) { create(:acl_user) }

    before do
      # Report user can access all projects for reporting
      report_collection = create(:collection)
      report_collection.set_viewables({ projects: [project_1.id, project_2.id, project_3.id] })

      setup_access_control(report_user, report_role, report_collection)

      # Project user can only access specific projects for client dashboards
      project_collection = create(:collection)
      project_collection.set_viewables({ projects: [project_1.id] })
      setup_access_control(project_user, project_role, project_collection)
    end

    it 'report and project access are separate using permissions' do
      # Test report access (uses can_view_assigned_reports)
      report_scope = GrdaWarehouse::Hud::Project.viewable_by(report_user, permission: :can_view_assigned_reports)

      # Test project access (uses can_view_projects)
      project_scope = GrdaWarehouse::Hud::Project.viewable_by(project_user, permission: :can_view_projects)

      # Report user can access projects for reporting
      expect(report_scope.pluck(:id)).to contain_exactly(project_1.id, project_2.id, project_3.id)

      # Project user can only access specific projects
      expect(project_scope.pluck(:id)).to contain_exactly(project_1.id)

      project_user_report_scope = GrdaWarehouse::Hud::Project.viewable_by(project_user, permission: :can_view_assigned_reports)
      report_user_project_scope = GrdaWarehouse::Hud::Project.viewable_by(report_user, permission: :can_view_projects)

      expect(project_user_report_scope.pluck(:id)).to be_empty
      expect(report_user_project_scope.pluck(:id)).to be_empty
    end

    it 'report and project access are separate using filter criteria' do
      # This test is redundant with the previous test, as `viewable_project_scope` is getting viewable_by `can_view_projects`
      # as is being tested above, but this is a more direct test of how the filter criteria is used in the wild

      # Test report_user's access to report data using viewable_project_scope
      report_filter = ::Filters::FilterBase.new(user_id: report_user.id)
      report_criteria = described_class.new(input: report_filter, config: config)
      report_user_report_scope = report_criteria.viewable_project_scope

      expect(report_user_report_scope.pluck(:id)).to include(project_1.id, project_2.id, project_3.id)

      # Test project_user's access to report data using viewable_project_scope
      project_filter = ::Filters::FilterBase.new(user_id: project_user.id)
      project_criteria = described_class.new(input: project_filter, config: config)
      project_user_report_scope = project_criteria.viewable_project_scope

      expect(project_user_report_scope.pluck(:id)).to be_empty
    end
  end

  describe 'confidentiality handling' do
    let(:confidential_role) { create(:role, can_view_confidential_project_names: true, can_report_on_confidential_projects: true) }
    let(:confidential_user) { create(:acl_user) }

    before do
      setup_access_control(confidential_user, confidential_role, Collection.system_collection(:data_sources))
    end

    it 'handles confidential projects correctly in viewable_project_scope' do
      confidential_filter = ::Filters::FilterBase.new(user_id: confidential_user.id)
      confidential_criteria = described_class.new(input: confidential_filter, config: config)

      scope = confidential_criteria.viewable_project_scope
      project_ids = scope.pluck(:id)

      # Should include confidential project when user has appropriate permissions
      expect(project_ids).to include(confidential_project.id)
    end

    it 'respects confidential organization settings' do
      # Create a project in a confidential organization
      confidential_org = create(:hud_organization, data_source_id: data_source.id, confidential: true)
      org_confidential_project = create_project(organization_id: confidential_org.organization_id, ProjectName: 'Org Confidential Project')

      confidential_filter = ::Filters::FilterBase.new(user_id: confidential_user.id)
      confidential_criteria = described_class.new(input: confidential_filter, config: config)

      scope = confidential_criteria.viewable_project_scope
      project_ids = scope.pluck(:id)

      # Should include project from confidential organization
      expect(project_ids).to include(org_confidential_project.id)
    end
  end

  describe 'integration with filter criteria' do
    let(:filter_for_projects) { Filters::Criteria::FilterForProjects.new(input: filter, config: config) }
    let(:filter_for_user_access) { Filters::Criteria::FilterForUserAccess.new(input: filter, config: config) }

    before do
      setup_access_control(user, role, Collection.system_collection(:data_sources))
    end

    it 'uses viewable_project_scope in FilterForUserAccess' do
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      result = filter_for_user_access.apply(scope)

      # Should only include enrollments from viewable projects
      project_ids_in_result = result.joins(:project).distinct.pluck(p_t[:id])
      viewable_project_ids = criteria.viewable_project_scope.pluck(:id)

      # The result should be a subset of viewable projects (some projects might not have enrollments)
      expect(project_ids_in_result - viewable_project_ids).to be_empty
    end

    it 'uses viewable_project_scope in FilterForProjects' do
      # Set specific project filter
      filter.project_ids = [project_1.id, project_2.id]

      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      result = filter_for_projects.apply(scope)

      # Should only include enrollments from the specified projects that are also viewable
      project_ids_in_result = result.joins(:project).distinct.pluck('Project.id')
      expected_project_ids = [project_1.id, project_2.id] & criteria.viewable_project_scope.pluck(:id)

      expect(project_ids_in_result).to match_array(expected_project_ids)
    end
  end

  describe 'edge cases' do
    it 'handles user with no roles' do
      user_without_roles = create(:acl_user)
      filter_no_roles = ::Filters::FilterBase.new(user_id: user_without_roles.id)
      criteria_no_roles = described_class.new(input: filter_no_roles, config: config)

      scope = criteria_no_roles.viewable_project_scope
      expect(scope).to be_empty
    end

    it 'handles empty collections' do
      # Create a completely new user with no permissions
      new_user = create(:acl_user)
      no_permission_role = create(:role, can_view_assigned_reports: false)
      empty_collection = create(:collection)
      setup_access_control(new_user, no_permission_role, empty_collection)

      # Create a new filter with the user that has no permissions
      no_permission_filter = ::Filters::FilterBase.new(user_id: new_user.id)
      no_permission_criteria = described_class.new(input: no_permission_filter, config: config)

      scope = no_permission_criteria.viewable_project_scope
      expect(scope).to be_empty
    end
  end
end
