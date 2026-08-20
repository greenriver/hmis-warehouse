###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project,
        )
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
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: data_source,
        )
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

      it 'returns the same permissions when warmed via preload_client_dependencies' do
        other_client = create(:hud_client)

        context.preload_client_dependencies([client.id, other_client.id])

        expect(context.direct_client_role_permissions(client.id)).to include(:can_view_projects)
        expect(context.direct_client_role_permissions(other_client.id)).to be_empty
      end
    end
  end

  describe '#preload_client_dependencies' do
    subject(:context) { described_class.new(acl_user) }
    let(:user_group) { create(:user_group) }
    let(:client_data_source) { create(:grda_warehouse_data_source, authoritative: true) }

    before do
      create(:access_control, role: role, collection: collection, user_group: user_group)
      user_group.add(acl_user)
      create(:grda_warehouse_group_viewable_entity, collection: collection, entity: client_data_source)
    end

    it 'warms project_role_permissions for a client\'s enrolled projects' do
      client = create(:hud_client, data_source: data_source)
      create(:hud_enrollment, client: client, project: project, data_source: data_source)
      create(:grda_warehouse_group_viewable_entity, collection: collection, entity: project)

      context.preload_client_dependencies([client.id])

      expect(context.enrolled_project_ids_for_client(client.id)).to eq([project.id])
      expect(context.project_role_permissions(project.id)).to include(:can_view_projects)
    end

    it 'reduces the queries needed to read back permissions, compared to no preload at all' do
      client = create(:hud_client, data_source: data_source)
      create(:hud_enrollment, client: client, project: project, data_source: data_source)
      create(:grda_warehouse_group_viewable_entity, collection: collection, entity: project)

      count_queries = lambda do |&block|
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      # Each of these still costs one query to compute the actual permission set the
      # first time -- preload_client_dependencies doesn't warm that per-collection-ids
      # cost. But without a working preload, each id-lookup step below would *also* run
      # its own per-id query, so a lazy fallback that silently re-ran them would leave
      # warm_queries no lower than cold_queries.
      cold_context = described_class.new(acl_user)
      cold_queries = count_queries.call do
        cold_context.direct_client_role_permissions(client.id)
        cold_context.enrolled_project_ids_for_client(client.id)
        cold_context.project_role_permissions(project.id)
      end

      warm_context = described_class.new(acl_user)
      warm_context.preload_client_dependencies([client.id])
      warm_queries = count_queries.call do
        warm_context.direct_client_role_permissions(client.id)
        warm_context.enrolled_project_ids_for_client(client.id)
        warm_context.project_role_permissions(project.id)
      end

      expect(warm_queries).to be < cold_queries
    end

    it 'runs a bounded number of queries regardless of client batch size' do
      small_batch = create_list(:hud_client, 3, data_source: client_data_source)
      large_batch = create_list(:hud_client, 15, data_source: client_data_source)

      count_queries = lambda do |&block|
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      small_context = described_class.new(acl_user)
      small_queries = count_queries.call do
        small_context.preload_client_dependencies(small_batch.map(&:id))
        small_batch.each { |c| small_context.direct_client_role_permissions(c.id) }
      end

      large_context = described_class.new(acl_user)
      large_queries = count_queries.call do
        large_context.preload_client_dependencies(large_batch.map(&:id))
        large_batch.each { |c| large_context.direct_client_role_permissions(c.id) }
      end

      # A regression to the old per-client query pattern would make large_queries scale
      # roughly with client count (5x more clients here); a small constant tolerance
      # accommodates incidental memoization-boundary variance without masking that regression.
      expect(large_queries).to be_within(2).of(small_queries)
    end

    it 'runs a bounded number of queries for enrolled-project lookups, even with unenrolled clients mixed in' do
      count_queries = lambda do |&block|
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      small_batch = create_list(:hud_client, 3, data_source: data_source)
      large_batch = create_list(:hud_client, 15, data_source: data_source)
      # Enroll only every other client so the batch also exercises clients with zero
      # enrolled projects.
      small_batch.each_with_index { |c, i| create(:hud_enrollment, client: c, project: project, data_source: data_source) if i.even? }
      large_batch.each_with_index { |c, i| create(:hud_enrollment, client: c, project: project, data_source: data_source) if i.even? }

      small_context = described_class.new(acl_user)
      small_queries = count_queries.call do
        small_context.preload_client_dependencies(small_batch.map(&:id))
        small_batch.each { |c| small_context.enrolled_project_ids_for_client(c.id) }
      end

      large_context = described_class.new(acl_user)
      large_queries = count_queries.call do
        large_context.preload_client_dependencies(large_batch.map(&:id))
        large_batch.each { |c| large_context.enrolled_project_ids_for_client(c.id) }
      end

      expect(large_queries).to be_within(2).of(small_queries)
    end
  end

  describe 'string mutation operations' do
    subject(:context) { described_class.new(acl_user) }
    let(:user_group) { create(:user_group) }

    before do
      create(:access_control, role: role, collection: collection, user_group: user_group)
      user_group.add(acl_user)
    end

    describe '#permissions_for_collection_ids with += mutation' do
      let(:test_collection_ids) { [collection.id] }
      let(:system_collection) { create(:collection, name: 'system_data_sources') }

      before do
        allow(Collection).to receive(:system_collection).with(:data_sources).and_return(system_collection)
      end

      it 'concatenates system collection IDs using += operator' do
        # Test the string mutation: collection_ids += system_collection_ids(:data_sources) from line 92
        permissions = context.send(:permissions_for_collection_ids, test_collection_ids)

        # Verify the method works correctly with the += operation
        expect(permissions).to be_a(Set)
        expect(permissions).to include(:can_view_projects)
      end

      it 'returns empty set when collection_ids becomes empty after += operation' do
        permissions = context.send(:permissions_for_collection_ids, [])

        expect(permissions).to eq(GrdaWarehouse::AuthPolicies::UserAclContext::EMPTY_SET)
      end
    end

    describe '#project_collection_ids with += mutation' do
      let(:project_coc) { create(:grda_warehouse_hud_project_coc, project: project, coc_code: 'MA-500') }
      let(:coc_collection) { create(:collection) }

      before do
        # Create the project_coc association
        project_coc

        # Mock the coc code collection lookup
        allow(Collection).to receive(:for_coc_codes).with(['MA-500']).and_return(double(pluck: [coc_collection.id]))

        # Create a project collection member so the method has something to start with
        create(:grda_warehouse_group_viewable_entity, collection: collection, entity: project)
      end

      it 'concatenates CoC collection IDs using += operator' do
        # Test the string mutation: collection_ids += collection_for_coc_codes(coc_codes) from line 115
        collection_ids = context.send(:project_collection_ids, project.id)

        # Verify that the += operation worked correctly
        expect(collection_ids).to be_an(Array)
        expect(collection_ids).to include(coc_collection.id)
        expect(collection_ids.uniq).to eq(collection_ids) # Should be unique
        expect(collection_ids).to eq(collection_ids.sort) # Should be sorted
      end

      it 'handles projects with no CoC codes' do
        other_project = create(:grda_warehouse_hud_project)
        create(:grda_warehouse_group_viewable_entity, collection: collection, entity: other_project)

        collection_ids = context.send(:project_collection_ids, other_project.id)

        # Should not include CoC collection IDs since there are no CoC codes
        expect(collection_ids).not_to include(coc_collection.id)
      end
    end
  end
end
