###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::OrganizationPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:other_organization) { create :hud_organization, data_source: data_source }
  let(:imports_role) { create(:role, can_view_imports: true) }
  let(:view_only_role) { create(:role, can_view_projects: true) }

  context 'with access control permissions' do
    let(:user) { create(:acl_user) }
    let(:policy) { user.policy_for(organization) }

    def grant(role, collection)
      user_group = create(:user_group)
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    def collection_with(viewables)
      create(:collection).tap { |collection| collection.set_viewables(viewables) }
    end

    it 'is true when Can View Imports is granted on a collection that includes the organization' do
      grant(imports_role, collection_with(organizations: [organization.id]))

      expect(policy.can_edit_contacts?).to be true
    end

    it 'is true when Can View Imports is granted on a collection that includes its data source' do
      grant(imports_role, collection_with(data_sources: [data_source.id]))

      expect(policy.can_edit_contacts?).to be true
    end

    it 'is true when Can View Imports is granted on the system data sources collection' do
      grant(imports_role, Collection.system_collection(:data_sources))

      expect(policy.can_edit_contacts?).to be true
    end

    it 'is false when the collection includes a different organization in the same data source' do
      grant(imports_role, collection_with(organizations: [other_organization.id]))

      expect(policy.can_edit_contacts?).to be false
    end

    it 'is false when the collection includes only one of the organization projects' do
      project = create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID)
      grant(imports_role, collection_with(projects: [project.id]))

      expect(policy.can_edit_contacts?).to be false
    end

    it 'is false after the collection that includes the organization is deleted' do
      collection = collection_with(organizations: [organization.id])
      grant(imports_role, collection)
      collection.destroy

      expect(policy.can_edit_contacts?).to be false
    end

    it 'is false when Can View Imports is granted only on a collection without the organization' do
      grant(imports_role, collection_with(organizations: [other_organization.id]))
      grant(view_only_role, collection_with(organizations: [organization.id]))

      expect(policy.can_edit_contacts?).to be false
    end

    describe '#can_view_name?' do
      let(:edit_role) { create(:role, can_view_projects: true, can_edit_organizations: true) }

      it 'is true for a non-confidential organization without any grant' do
        expect(policy.can_view_name?).to be true
      end

      context 'with a confidential organization' do
        before { organization.update!(confidential: true) }

        it 'is true when Can Edit Organizations is granted on a collection that includes the organization' do
          grant(edit_role, collection_with(organizations: [organization.id]))

          expect(policy.can_view_name?).to be true
        end

        it 'is false when Can Edit Organizations is granted only on a collection without the organization' do
          grant(view_only_role, collection_with(organizations: [organization.id]))
          grant(edit_role, collection_with(organizations: [other_organization.id]))

          expect(policy.can_view_name?).to be false
        end

        it 'is false when Can View Confidential Project Names is granted only on a collection without the organization' do
          grant(view_only_role, collection_with(organizations: [organization.id]))
          grant(
            create(:role, can_view_projects: true, can_view_confidential_project_names: true),
            collection_with(organizations: [other_organization.id]),
          )

          expect(policy.can_view_name?).to be false
          expect(organization.name(user)).to eq(GrdaWarehouse::Hud::Organization.confidential_organization_name)
        end

        describe 'from a project in the organization' do
          let(:confidential_names_role) { create(:role, can_view_projects: true, can_view_confidential_project_names: true) }
          let!(:project) do
            create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Project')
          end
          let(:masked_organization_name) { GrdaWarehouse::Hud::Organization.confidential_organization_name }

          it 'shows only the project name when Can View Confidential Project Names is granted on the project' do
            grant(confidential_names_role, collection_with(projects: [project.id]))

            expect(policy.can_view_name?).to be false
            expect(project.name(user)).to eq('Hidden Project')
            expect(project.organization_name(user)).to eq(masked_organization_name)
            expect(project.organization_and_name(user)).to eq('Hidden Project')
          end

          it 'shows the organization and project names when Can View Confidential Project Names is granted on the organization' do
            grant(confidential_names_role, collection_with(organizations: [organization.id]))

            expect(project.organization_name(user)).to eq(organization.OrganizationName)
            expect(project.organization_and_name(user)).to eq("#{organization.OrganizationName} / Hidden Project")
          end

          it 'masks the organization name when Can View Confidential Project Names is granted only on another organization' do
            grant(view_only_role, collection_with(organizations: [organization.id]))
            grant(confidential_names_role, collection_with(organizations: [other_organization.id]))

            expect(project.organization_name(user)).to eq(masked_organization_name)
            expect(project.organization_and_name(user)).to eq(GrdaWarehouse::Hud::Project.confidential_project_name)
          end
        end
      end

      describe 'from a confidential project with no matching organization' do
        let!(:orphan_project) do
          create(
            :hud_project,
            data_source: data_source,
            OrganizationID: 'no-such-organization',
            ProjectName: 'Orphan Project',
            confidential: true,
          )
        end

        it 'shows only the project name and masks the organization name' do
          grant(
            create(:role, can_view_projects: true, can_view_confidential_project_names: true),
            collection_with(projects: [orphan_project.id]),
          )

          expect(orphan_project.organization_and_name(user)).to eq('Orphan Project')
          expect(orphan_project.organization_name(user)).to eq(GrdaWarehouse::Hud::Organization.confidential_organization_name)
        end
      end
    end
  end

  context 'with legacy role permissions' do
    let(:user) { create(:user) }
    let(:access_group) { create(:access_group) }
    let(:policy) { user.policy_for(organization) }

    before { access_group.add(user) }

    context 'with Can View Imports' do
      before { imports_role.add(user) }

      it 'is true when an access group includes the organization' do
        access_group.add_viewable(organization)

        expect(policy.can_edit_contacts?).to be true
      end

      it 'is true when an access group includes its data source' do
        access_group.add_viewable(data_source)

        expect(policy.can_edit_contacts?).to be true
      end

      it 'is true for a member of the system data sources group' do
        AccessGroup.system_groups[:data_sources].add(user)

        expect(policy.can_edit_contacts?).to be true
      end

      it 'is false after the access group that includes the organization is deleted' do
        access_group.add_viewable(organization)
        access_group.destroy

        expect(policy.can_edit_contacts?).to be false
      end

      it 'is false when no access group includes the organization or its data source' do
        access_group.add_viewable(other_organization)

        expect(policy.can_edit_contacts?).to be false
      end
    end

    it 'is false when an access group includes the organization but no role grants Can View Imports' do
      view_only_role.add(user)
      access_group.add_viewable(organization)

      expect(policy.can_edit_contacts?).to be false
    end

    describe '#can_view_name?' do
      let(:masked_organization_name) { GrdaWarehouse::Hud::Organization.confidential_organization_name }

      context 'with a confidential organization and Can View Confidential Project Names' do
        let!(:project) do
          create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Project')
        end

        before do
          organization.update!(confidential: true)
          create(:role, can_view_projects: true, can_view_confidential_project_names: true).add(user)
        end

        it 'is true when an access group includes the organization' do
          access_group.add_viewable(organization)

          expect(policy.can_view_name?).to be true
          expect(organization.name(user)).to eq(organization.OrganizationName)
          expect(project.organization_and_name(user)).to eq("#{organization.OrganizationName} / Hidden Project")
        end

        it 'is true when an access group includes its data source' do
          access_group.add_viewable(data_source)

          expect(policy.can_view_name?).to be true
          expect(project.organization_name(user)).to eq(organization.OrganizationName)
        end

        it 'is true when an access group includes only a project in the organization' do
          access_group.add_viewable(project)

          expect(policy.can_view_name?).to be true
          expect(organization.name(user)).to eq(organization.OrganizationName)
          expect(project.organization_and_name(user)).to eq("#{organization.OrganizationName} / Hidden Project")
        end

        it 'is true when no access group includes the organization, but masks it on projects the user cannot view' do
          access_group.add_viewable(other_organization)

          expect(policy.can_view_name?).to be true
          expect(organization.name(user)).to eq(organization.OrganizationName)
          expect(project.organization_name(user)).to eq(masked_organization_name)
        end

        it 'is false without Can View Confidential Project Names' do
          other_user = create(:user)
          view_only_role.add(other_user)
          access_group.add(other_user)
          access_group.add_viewable(organization)

          expect(other_user.policy_for(organization).can_view_name?).to be false
          expect(organization.name(other_user)).to eq(masked_organization_name)
        end
      end
    end
  end

  it 'raises for a resource that is not an organization' do
    expect { create(:user).policy_for(data_source, policy_class: described_class) }.to raise_error(ArgumentError)
  end
end
