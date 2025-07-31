# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::UserAclContext do
  let(:data_source) { create(:data_source_fixed_id) }
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: data_source) }
  let(:role) { create(:role, can_view_projects: true) }
  let(:acl_user) { create(:acl_user) }
  let(:legacy_user) { create(:user) }
  let(:collection) { create(:collection) }

  describe '#initialize' do
    it 'initializes for an acl user' do
      expect { described_class.new(acl_user) }.not_to raise_error
    end

    it 'raises an error for a legacy user' do
      expect { described_class.new(legacy_user) }.to raise_error(ArgumentError, 'must be acl user')
    end
  end

  describe 'permission caching' do
    let(:user_group) { create(:user_group) }
    subject(:context) { described_class.new(acl_user) }

    before do
      create(:access_control, role: role, collection: collection, user_group: user_group)
      user_group.add(acl_user)
    end

    describe '#project_role_permissions' do
      before do
        create(:grda_warehouse_group_viewable_entity,
               collection: collection,
               entity: project)
      end

      it 'returns correct permissions for a project' do
        expect(context.project_role_permissions(project.id)).to include(:can_view_projects)
      end

      it 'returns empty set when project has no collections' do
        other_project = create(:grda_warehouse_hud_project)
        expect(context.project_role_permissions(other_project.id)).to be_empty
      end

      it 'filters out deleted collections' do
        collection.destroy
        expect(described_class.new(acl_user).project_role_permissions(project.id)).to be_empty
      end
    end

    describe '#data_source_role_permissions' do
      before do
        create(:grda_warehouse_group_viewable_entity,
               collection: collection,
               entity: data_source)
      end

      it 'returns correct permissions for a data source' do
        expect(context.data_source_role_permissions(data_source.id)).to include(:can_view_projects)
      end

      it 'returns empty set when data source has no collections' do
        other_data_source = create(:grda_warehouse_data_source)
        expect(context.data_source_role_permissions(other_data_source.id)).to be_empty
      end

      it 'filters out deleted collections' do
        collection.destroy
        expect(described_class.new(acl_user).data_source_role_permissions(data_source.id)).to be_empty
      end
    end

    describe '#direct_client_role_permissions' do
      let(:client_data_source) { create(:grda_warehouse_data_source, authoritative: true) }
      let(:client) { create(:hud_client, data_source: client_data_source) }

      before do
        create(:grda_warehouse_group_viewable_entity,
               collection: collection,
               entity: client_data_source)
      end

      it 'returns correct permissions for a direct client' do
        expect(context.direct_client_role_permissions(client.id)).to include(:can_view_projects)
      end

      it 'returns empty set for client with no collections' do
        other_client = create(:hud_client)
        expect(context.direct_client_role_permissions(other_client.id)).to be_empty
      end

      it 'filters out deleted collections' do
        collection.destroy
        expect(described_class.new(acl_user).direct_client_role_permissions(client.id)).to be_empty
      end
    end
  end
end
