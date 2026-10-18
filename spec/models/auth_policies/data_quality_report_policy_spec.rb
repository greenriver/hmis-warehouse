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
  let(:other_organization) { create :hud_organization, data_source: data_source }
  let(:project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
  let(:other_project) { create :hud_project, data_source: data_source, OrganizationID: other_organization.OrganizationID }
  let(:project_group) { create :project_group, projects: [project] }
  let(:other_project_group) { create :project_group, projects: [other_project] }
  let(:other_user) { create(:user) }
  let(:requestor_id) { user.id }
  let(:project_report) { create :data_quality_report_version_five, project: project, requestor_id: requestor_id }
  let(:group_report) { create :data_quality_report_version_five, project: nil, project_group: project_group, requestor_id: requestor_id }
  let(:reporting_role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let(:all_reports_role) { create(:role, can_view_assigned_reports: true, can_view_all_reports: true, can_view_projects: true) }

  def can_view?(report)
    user.policy_for(report).can_view?
  end

  it 'raises for a resource that is not a data quality report' do
    user = create(:acl_user)

    expect { described_class.new(context: user.policy_context, resource: project) }.to raise_error(ArgumentError)
  end

  context 'with access control permissions' do
    let(:user) { create(:acl_user) }
    let(:project_viewer_role) { create(:role, can_view_projects: true) }

    def grant(role, collection)
      user_group = create(:user_group)
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
      user.clear_memery_cache!
    end

    def collection_with(viewables)
      create(:collection).tap { |collection| collection.set_viewables(viewables) }
    end

    describe 'the requestor' do
      it 'is allowed when the collection holds the project' do
        grant(reporting_role, collection_with(projects: [project.id]))

        expect(can_view?(project_report)).to be true
      end

      it 'is allowed when the collection holds the project organization' do
        grant(reporting_role, collection_with(organizations: [organization.id]))

        expect(can_view?(project_report)).to be true
      end

      it 'is denied when the collection holds only a different project' do
        grant(reporting_role, collection_with(projects: [other_project.id]))

        expect(can_view?(project_report)).to be false
      end

      it 'is denied when the project is only in a collection whose role lacks can_view_assigned_reports' do
        grant(reporting_role, collection_with(projects: [other_project.id]))
        grant(project_viewer_role, collection_with(projects: [project.id]))

        expect(can_view?(project_report)).to be false
      end

      it 'is allowed for a group report when the collection holds the group' do
        grant(reporting_role, collection_with(project_groups: [project_group.id]))

        expect(can_view?(group_report)).to be true
      end

      it 'is denied for a group report when the collection holds only a different group' do
        grant(reporting_role, collection_with(project_groups: [other_project_group.id]))

        expect(can_view?(group_report)).to be false
      end
    end

    describe 'a user who did not request the report' do
      let(:requestor_id) { other_user.id }

      it 'is denied without can_view_all_reports when the collection holds the project' do
        grant(reporting_role, collection_with(projects: [project.id]))

        expect(can_view?(project_report)).to be false
      end

      it 'is allowed with can_view_all_reports when the collection holds the project' do
        grant(all_reports_role, collection_with(projects: [project.id]))

        expect(can_view?(project_report)).to be true
      end

      it 'is denied with can_view_all_reports when the collection holds only a different project' do
        grant(all_reports_role, collection_with(projects: [other_project.id]))

        expect(can_view?(project_report)).to be false
      end
    end

    describe 'a contact with no access to the project' do
      let(:requestor_id) { other_user.id }

      it 'is allowed as a project contact' do
        create(:grda_warehouse_contact_project, entity: project, user: user)

        expect(can_view?(project_report)).to be true
      end

      it 'is allowed as an organization contact' do
        create(:grda_warehouse_contact_organization, entity: organization, user: user)

        expect(can_view?(project_report)).to be true
      end

      it 'is denied as a contact on a different project' do
        create(:grda_warehouse_contact_project, entity: other_project, user: user)

        expect(can_view?(project_report)).to be false
      end

      it 'is denied as a contact on a different organization' do
        create(:grda_warehouse_contact_organization, entity: other_organization, user: user)

        expect(can_view?(project_report)).to be false
      end

      it 'is denied once the project contact is deleted' do
        create(:grda_warehouse_contact_project, entity: project, user: user).destroy

        expect(can_view?(project_report)).to be false
      end

      it 'is allowed for a group report as a contact on a project in the group' do
        create(:grda_warehouse_contact_project, entity: project, user: user)

        expect(can_view?(group_report)).to be true
      end

      it 'is allowed for a group report as an organization contact on a project in the group' do
        create(:grda_warehouse_contact_organization, entity: organization, user: user)

        expect(can_view?(group_report)).to be true
      end

      it 'is denied for a group report as a contact on a project outside the group' do
        create(:grda_warehouse_contact_project, entity: other_project, user: user)

        expect(can_view?(group_report)).to be false
      end
    end

    describe '#can_view_client_details?' do
      let(:client_role) { create(:role, can_view_clients: true) }
      let(:client_reporting_role) { create(:role, can_view_assigned_reports: true, can_view_projects: true, can_view_clients: true) }

      def can_view_client_details?(report)
        user.policy_for(report).can_view_client_details?
      end

      it 'is true for the requestor holding can_view_clients on the project' do
        grant(client_reporting_role, collection_with(projects: [project.id]))

        expect(can_view_client_details?(project_report)).to be true
      end

      context 'for a project contact who did not request the report' do
        let(:requestor_id) { other_user.id }

        before { create(:grda_warehouse_contact_project, entity: project, user: user) }

        it 'is false without client access to the project' do
          expect(can_view?(project_report)).to be true
          expect(can_view_client_details?(project_report)).to be false
        end

        it 'is false when can_view_clients covers only a different project' do
          grant(client_role, collection_with(projects: [other_project.id]))

          expect(can_view_client_details?(project_report)).to be false
        end

        it 'is true when can_view_clients covers the project' do
          grant(client_role, collection_with(projects: [project.id]))

          expect(can_view_client_details?(project_report)).to be true
        end
      end

      context 'for a group report with two projects' do
        let(:project_group) { create :project_group, projects: [project, other_project] }

        before { grant(reporting_role, collection_with(project_groups: [project_group.id])) }

        it 'is false when can_view_clients covers one of the projects' do
          grant(client_role, collection_with(projects: [project.id]))

          expect(can_view?(group_report)).to be true
          expect(can_view_client_details?(group_report)).to be false
        end

        it 'is true when can_view_clients covers both projects' do
          grant(client_role, collection_with(projects: [project.id, other_project.id]))

          expect(can_view_client_details?(group_report)).to be true
        end
      end

      it 'is false for a group report on a group with no projects' do
        empty_group = create :project_group, projects: []
        grant(reporting_role, collection_with(project_groups: [empty_group.id]))
        grant(client_role, collection_with(projects: [project.id]))
        report = create :data_quality_report_version_five, project: nil, project_group: empty_group, requestor_id: user.id

        expect(can_view?(report)).to be true
        expect(can_view_client_details?(report)).to be false
      end
    end

    describe '.viewable_reports' do
      it 'lists exactly the reports the user requested on reportable projects or is a contact for' do
        grant(reporting_role, collection_with(projects: [project.id]))
        contact_project = create :hud_project, data_source: data_source, OrganizationID: other_organization.OrganizationID
        create(:grda_warehouse_contact_project, entity: contact_project, user: user)
        requested = create :data_quality_report_version_five, project: project, requestor_id: user.id
        contacted = create :data_quality_report_version_five, project: contact_project, requestor_id: other_user.id
        create :data_quality_report_version_five, project: project, requestor_id: other_user.id
        create :data_quality_report_version_five, project: other_project, requestor_id: user.id

        expect(described_class.viewable_reports(user)).to contain_exactly(requested, contacted)
      end
    end

    describe '.reportable_project_ids and .reportable_project_group_ids' do
      before do
        grant(reporting_role, collection_with(projects: [project.id], project_groups: [project_group.id]))
        grant(project_viewer_role, collection_with(projects: [other_project.id], project_groups: [other_project_group.id]))
      end

      it 'returns only projects in a collection whose role has can_view_assigned_reports' do
        expect(GrdaWarehouse::Hud::Project.where(id: described_class.reportable_project_ids(user))).to contain_exactly(project)
      end

      it 'returns only project groups in a collection whose role has can_view_assigned_reports' do
        expect(GrdaWarehouse::ProjectGroup.where(id: described_class.reportable_project_group_ids(user))).to contain_exactly(project_group)
      end
    end
  end

  context 'with legacy role permissions' do
    let(:user) { create(:user) }
    let(:access_group) { create(:access_group) }
    let(:role) { reporting_role }

    before do
      access_group.add(user)
      role.add(user)
    end

    it 'allows the requestor when an access group holds the project' do
      access_group.add_viewable(project)

      expect(can_view?(project_report)).to be true
    end

    it 'denies the requestor when the access group holds only a different project' do
      access_group.add_viewable(other_project)

      expect(can_view?(project_report)).to be false
    end

    it 'allows the requestor of a group report when an access group holds the group' do
      access_group.add_viewable(project_group)

      expect(can_view?(group_report)).to be true
    end

    it 'denies the requestor of a group report when the access group holds only a different group' do
      access_group.add_viewable(other_project_group)

      expect(can_view?(group_report)).to be false
    end

    it 'allows a project contact whose access group does not hold the project' do
      access_group.add_viewable(other_project)
      create(:grda_warehouse_contact_project, entity: project, user: user)
      other_report = create :data_quality_report_version_five, project: project, requestor_id: other_user.id

      expect(can_view?(other_report)).to be true
    end

    context 'when the user did not request the report' do
      let(:requestor_id) { other_user.id }

      before { access_group.add_viewable(project) }

      it 'denies a user without can_view_all_reports' do
        expect(can_view?(project_report)).to be false
      end

      context 'with can_view_all_reports' do
        let(:role) { all_reports_role }

        it 'allows the user' do
          expect(can_view?(project_report)).to be true
        end
      end
    end
  end
end
