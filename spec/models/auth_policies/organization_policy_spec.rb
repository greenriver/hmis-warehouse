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
  end

  it 'raises for a resource that is not an organization' do
    expect { create(:user).policy_for(data_source, policy_class: described_class) }.to raise_error(ArgumentError)
  end
end
