# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::UserLegacyContext do
  let(:data_source) { create(:data_source_fixed_id) }
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: data_source) }
  let(:role) { create(:role, can_view_projects: true) }
  let(:legacy_user) do
    user = create(:user)
    user.legacy_roles << role
    user
  end
  let(:acl_user) { create(:acl_user) }
  let(:access_group) { create(:access_group) }

  describe '#initialize' do
    it 'initializes for a legacy user' do
      expect { described_class.new(legacy_user) }.not_to raise_error
    end

    it 'raises an error for an ACL user' do
      expect { described_class.new(acl_user) }.to raise_error(ArgumentError, 'cannot be acl user')
    end
  end

  describe 'permission caching' do
    subject(:context) { described_class.new(legacy_user) }

    before do
      legacy_user.access_groups << access_group
    end

    describe '#project_role_permissions' do
      before do
        group = create(:project_access_group)
        access_group.add_viewable(group)
        project.project_groups << group
        project.save!
      end

      it 'returns correct permissions for a project' do
        expect(context.project_role_permissions(project.id)).to include(:can_view_projects)
      end

      it 'returns empty set when project has no access groups' do
        other_project = create(:grda_warehouse_hud_project)
        expect(context.project_role_permissions(other_project.id)).to be_empty
      end

      it 'filters out deleted access groups' do
        access_group.destroy
        expect(described_class.new(legacy_user).project_role_permissions(project.id)).to be_empty
      end
    end

    describe '#data_source_role_permissions' do
      before do
        create(:grda_warehouse_group_viewable_entity,
               access_group: access_group,
               entity: data_source)
      end

      it 'returns correct permissions for a data source' do
        expect(context.data_source_role_permissions(data_source.id)).to include(:can_view_projects)
      end

      it 'returns empty set when data source has no access groups' do
        other_data_source = create(:grda_warehouse_data_source)
        expect(context.data_source_role_permissions(other_data_source.id)).to be_empty
      end

      it 'filters out deleted access groups' do
        access_group.destroy
        expect(described_class.new(legacy_user).data_source_role_permissions(data_source.id)).to be_empty
      end
    end

    describe '#direct_client_role_permissions' do
      let(:client_data_source) { create(:grda_warehouse_data_source, authoritative: true) }
      let(:client) { create(:hud_client, data_source: client_data_source) }

      before do
        create(:grda_warehouse_group_viewable_entity,
               access_group: access_group,
               entity: client_data_source)
      end

      it 'returns correct permissions for a direct client' do
        expect(context.direct_client_role_permissions(client.id)).to include(:can_view_projects)
      end

      it 'returns empty set for client with no access groups' do
        other_client = create(:hud_client)
        expect(context.direct_client_role_permissions(other_client.id)).to be_empty
      end

      it 'filters out deleted access groups' do
        access_group.destroy
        expect(described_class.new(legacy_user).direct_client_role_permissions(client.id)).to be_empty
      end
    end
  end

  describe 'string mutation operations' do
    subject(:context) { described_class.new(legacy_user) }

    before do
      legacy_user.access_groups << access_group
    end

    describe '#permissions_for_access_group_ids with += mutation' do
      let(:test_access_group_ids) { [access_group.id] }
      let(:system_access_group) { create(:access_group, name: 'system_data_sources') }

      before do
        allow(AccessGroup).to receive(:system_groups).and_return({ data_sources: system_access_group })
      end

      it 'concatenates system access group IDs using += operator' do
        # Test the string mutation: access_group_ids += system_access_group_ids(:data_sources) from line 99
        permissions = context.send(:permissions_for_access_group_ids, test_access_group_ids)

        # Verify the method works correctly with the += operation
        expect(permissions).to be_a(Set)
        expect(permissions).to include(:can_view_projects)
      end

      it 'returns empty set when access_group_ids becomes empty after += operation' do
        permissions = context.send(:permissions_for_access_group_ids, [])

        expect(permissions).to eq(GrdaWarehouse::AuthPolicies::UserLegacyContext::EMPTY_SET)
      end

      it 'returns empty set when user has no access to access groups' do
        other_user = create(:user)
        other_user.legacy_roles << role
        other_context = described_class.new(other_user)

        permissions = other_context.send(:permissions_for_access_group_ids, test_access_group_ids)

        expect(permissions).to eq(GrdaWarehouse::AuthPolicies::UserLegacyContext::EMPTY_SET)
      end
    end

    describe '#project_access_group_ids with += mutation' do
      let(:project_coc) { create(:grda_warehouse_hud_project_coc, project: project, coc_code: 'MA-500') }
      let(:coc_access_group) { create(:access_group) }

      before do
        # Create the project_coc association
        project_coc

        # Mock the coc code access group lookup
        allow(AccessGroup).to receive(:for_coc_codes).with(['MA-500']).and_return(double(pluck: [coc_access_group.id]))

        # Create a project access group member so the method has something to start with
        create(:grda_warehouse_group_viewable_entity, access_group: access_group, entity: project)
      end

      it 'concatenates CoC access group IDs using += operator' do
        # Test the string mutation: access_group_ids += access_group_for_coc_codes(coc_codes) from line 121
        access_group_ids = context.send(:project_access_group_ids, project.id)

        # Verify that the += operation worked correctly
        expect(access_group_ids).to be_an(Array)
        expect(access_group_ids).to include(coc_access_group.id)
        expect(access_group_ids.uniq).to eq(access_group_ids) # Should be unique
        expect(access_group_ids).to eq(access_group_ids.sort) # Should be sorted
      end

      it 'handles projects with no CoC codes' do
        other_project = create(:grda_warehouse_hud_project)
        create(:grda_warehouse_group_viewable_entity, access_group: access_group, entity: other_project)

        access_group_ids = context.send(:project_access_group_ids, other_project.id)

        # Should not include CoC access group IDs since there are no CoC codes
        expect(access_group_ids).not_to include(coc_access_group.id)
      end
    end
  end
end
