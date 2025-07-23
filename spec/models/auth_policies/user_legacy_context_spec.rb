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
end
