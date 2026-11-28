###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Cohort, type: :model do
  let!(:cohort_manager) { create :cohort_manager }
  let!(:cohort_editor) { create :cohort_client_editor }
  let!(:cohort_viewer) { create :cohort_client_viewer }

  let!(:user) { create :acl_user }
  let!(:admin) { create :acl_user }
  let!(:editor) { create :acl_user }
  let!(:viewer) { create :acl_user }

  let!(:client) { create :hud_client }
  let!(:cohort) { create :cohort }
  let!(:cohort_2) { create :cohort }
  let!(:cohort_client) { create :cohort_client, cohort: cohort, client: client }
  let(:adjusted_days_homeless) { build :adjusted_days_homeless, cohort: cohort }
  let(:rank) { build :rank, cohort: cohort }

  let!(:no_permission_role) { create :role }
  let!(:empty_collection) { create :collection, collection_type: 'Cohorts' }
  let!(:cohort_collection) { create :collection, collection_type: 'Cohorts' }

  before(:each) do
    cohort_collection.set_viewables({ cohorts: [cohort.id] })
    setup_access_control(user, no_permission_role, cohort_collection)
    setup_access_control(admin, cohort_manager, cohort_collection)
    setup_access_control(admin, cohort_editor, cohort_collection)
  end

  describe 'viewable_by followed by a merge on cohort id' do
    before do
      setup_access_control(viewer, cohort_viewer, cohort_collection)
    end

    it 'does not widen to an invisible cohort' do
      scope = described_class.viewable_by(viewer).merge(described_class.where(id: cohort_2.id))
      expect(scope.pluck(:id)).to be_empty
    end

    it 'intersects with the merged ids' do
      scope = described_class.viewable_by(viewer).merge(described_class.where(id: [cohort.id, cohort_2.id]))
      expect(scope.pluck(:id)).to eq [cohort.id]
    end
  end

  describe 'when a user with no roles accesses a cohort column' do
    it 'display_as_editable? should always return false' do
      expect(adjusted_days_homeless.display_as_editable?(user, cohort_client)).to be_falsey
    end
    it 'display_as_editable? should always return false' do
      expect(rank.display_as_editable?(user, cohort_client)).to be_falsey
    end
  end
  describe 'when a user with a cohort management role accesses a cohort column' do
    it 'display_as_editable? should always return true' do
      expect(adjusted_days_homeless.display_as_editable?(admin, cohort_client)).to be true
    end
    it 'display_as_editable? should always return true' do
      expect(rank.display_as_editable?(admin, cohort_client)).to be true
    end
  end

  describe 'when a user with a cohort editor role accesses a cohort column' do
    it 'display_as_editable? should return false if no cohorts have been assigned' do
      expect(adjusted_days_homeless.display_as_editable?(editor, cohort_client)).to be_falsey
    end
    it 'display_as_editable? should return true if cohorts have been assigned' do
      cohort_collection.set_viewables({ cohorts: [cohort.id] })
      setup_access_control(editor, cohort_editor, cohort_collection)
      expect(adjusted_days_homeless.display_as_editable?(editor, cohort_client)).to be true
    end
    it 'display_as_editable? should return false if cohorts have been assigned, but the column is in another cohort' do
      cohort_collection.set_viewables({ cohorts: [cohort_2.id] })
      setup_access_control(editor, cohort_editor, cohort_collection)
      expect(adjusted_days_homeless.display_as_editable?(editor, cohort_client)).to be_falsey
    end
    it 'user should have access to assigned cohorts' do
      cohort_collection.set_viewables({ cohorts: [cohort.id] })
      setup_access_control(editor, cohort_editor, cohort_collection)
      expect(GrdaWarehouse::Cohort.viewable_by(editor).where(id: cohort.id).exists?).to be true
    end
    it 'user should not have access to other cohorts' do
      cohort_collection.set_viewables({ cohorts: [cohort_2.id] })
      setup_access_control(editor, cohort_editor, cohort_collection)
      expect(GrdaWarehouse::Cohort.viewable_by(editor).where(id: cohort.id).exists?).to be_falsey
    end
  end

  describe 'when a user with a cohort viewer role accesses a cohort column' do
    it 'display_as_editable? should always return false' do
      expect(adjusted_days_homeless.display_as_editable?(viewer, cohort_client)).to be_falsey
    end
    it 'display_as_editable? should always return false, even if a cohort is assigned' do
      cohort_collection.set_viewables({ cohorts: [cohort.id] })
      setup_access_control(viewer, cohort_viewer, cohort_collection)
      expect(adjusted_days_homeless.display_as_editable?(viewer, cohort_client)).to be_falsey
    end
    it 'display_as_editable? should always return false, even if another cohort is assigned' do
      cohort_collection.set_viewables({ cohorts: [cohort_2.id] })
      setup_access_control(viewer, cohort_viewer, cohort_collection)
      expect(adjusted_days_homeless.display_as_editable?(viewer, cohort_client)).to be_falsey
    end
    it 'user should have access to assigned cohorts' do
      cohort_collection.set_viewables({ cohorts: [cohort.id] })
      setup_access_control(viewer, cohort_viewer, cohort_collection)
      expect(GrdaWarehouse::Cohort.viewable_by(viewer).where(id: cohort.id).exists?).to be true
    end
    it 'user should not have access to other cohorts' do
      cohort_collection.set_viewables({ cohorts: [cohort_2.id] })
      setup_access_control(viewer, cohort_viewer, cohort_collection)
      expect(GrdaWarehouse::Cohort.viewable_by(viewer).where(id: cohort.id).exists?).to be_falsey
    end
  end
  describe '#system_collection' do
    let(:user) { create(:user) }
    let(:user_2) { create(:user) }
    let(:cohort) { create(:cohort, name: 'Old Name') }

    it 'returns the same system collection when the name changes and replace_access is called' do
      original_collection = cohort.system_collection
      original_viewable_user_group = cohort.system_viewable_user_group
      original_editable_user_group = cohort.system_editable_user_group
      cohort.replace_access(user, scope: :editor)

      # Verify the original collection name matches Cohort's name
      expect(original_collection.name).to eq('Old Name')

      # This is a regression catch, historically, changing the project name
      # would cause a new collection and user_group to be created
      # Update the Cohort's name
      cohort.update!(name: 'New Name')

      # Calling replace_access (which triggers the entity access logic)
      cohort.replace_access([user, user_2], scope: :editor)

      # Force re-calculation
      cohort.instance_variable_set(:@system_collection, nil)
      cohort.instance_variable_set(:@system_viewable_user_group, nil)
      cohort.instance_variable_set(:@system_editable_user_group, nil)
      updated_collection = cohort.system_collection
      updated_viewable_user_group = cohort.system_viewable_user_group
      updated_editable_user_group = cohort.system_editable_user_group

      # Confirm the IDs have not changed (i.e., it's still the same record)
      expect(updated_collection.id).to eq(original_collection.id)
      expect(updated_viewable_user_group.id).to eq(original_viewable_user_group.id)
      expect(updated_editable_user_group.id).to eq(original_editable_user_group.id)
      # Confirm the collection's name has been updated to match the new Cohort name
      expect(updated_collection.name).to eq('New Name')
    end
  end

  describe '.viewable_by with permission:' do
    let!(:acl_user) { create :acl_user }
    let!(:target_cohort) { create :cohort }
    let!(:name_role) { create(:cohort_client_viewer, can_view_client_name: true) }
    let!(:no_name_role) { create(:cohort_client_viewer) }
    let!(:name_collection) { create :collection, collection_type: 'Cohorts' }
    let!(:no_name_collection) { create :collection, collection_type: 'Cohorts' }

    context "when the granting collection's role has can_view_client_name" do
      before do
        name_collection.set_viewables({ cohorts: [target_cohort.id] })
        setup_access_control(acl_user, name_role, name_collection)
      end

      it 'includes the cohort' do
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user, permission: :can_view_client_name).pluck(:id)).to contain_exactly(target_cohort.id)
      end
    end

    context "when the granting collection's role lacks can_view_client_name" do
      before do
        no_name_collection.set_viewables({ cohorts: [target_cohort.id] })
        setup_access_control(acl_user, no_name_role, no_name_collection)
      end

      it 'excludes the cohort even though the user can view_cohorts' do
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user).pluck(:id)).to contain_exactly(target_cohort.id)
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user, permission: :can_view_client_name).pluck(:id)).to be_empty
      end
    end

    context 'when the user reaches the same cohort via two collections, only one granting can_view_client_name' do
      before do
        no_name_collection.set_viewables({ cohorts: [target_cohort.id] })
        setup_access_control(acl_user, no_name_role, no_name_collection)
        name_collection.set_viewables({ cohorts: [target_cohort.id] })
        setup_access_control(acl_user, name_role, name_collection)
      end

      it 'includes the cohort because at least one path grants it' do
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user, permission: :can_view_client_name).pluck(:id)).to contain_exactly(target_cohort.id)
      end
    end

    context 'when passed an array of permissions' do
      let!(:other_permission_role) { create(:cohort_client_viewer, can_view_cohorts: false, can_manage_cohort_data: true) }
      let!(:other_permission_collection) { create :collection, collection_type: 'Cohorts' }

      before do
        other_permission_collection.set_viewables({ cohorts: [target_cohort.id] })
        setup_access_control(acl_user, other_permission_role, other_permission_collection)
      end

      it 'includes the cohort when the granting role matches any permission in the array' do
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user, permission: [:can_view_cohorts, :can_manage_cohort_data]).pluck(:id)).to contain_exactly(target_cohort.id)
      end

      it 'excludes the cohort when checking only a permission the granting role lacks' do
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user, permission: :can_view_cohorts).pluck(:id)).to be_empty
      end

      it 'includes the cohort by default because an edit permission alone grants visibility' do
        expect(GrdaWarehouse::Cohort.viewable_by(acl_user).pluck(:id)).to contain_exactly(target_cohort.id)
      end
    end
  end

  describe '.editable_by for an ACL user' do
    let!(:acl_user) { create :acl_user }
    let!(:target_cohort) { create :cohort }
    let!(:collection) { create :collection, collection_type: 'Cohorts' }

    before { collection.set_viewables({ cohorts: [target_cohort.id] }) }

    it 'includes a cohort granted through a collection whose role can edit' do
      setup_access_control(acl_user, create(:cohort_client_editor), collection)

      expect(GrdaWarehouse::Cohort.editable_by(acl_user).pluck(:id)).to contain_exactly(target_cohort.id)
    end

    it 'includes a cohort granted through a role that can manage cohort data but cannot view cohorts' do
      setup_access_control(acl_user, create(:cohort_client_viewer, can_view_cohorts: false, can_manage_cohort_data: true), collection)

      expect(GrdaWarehouse::Cohort.editable_by(acl_user).pluck(:id)).to contain_exactly(target_cohort.id)
    end

    it 'excludes a cohort whose granting role can only view' do
      setup_access_control(acl_user, create(:cohort_client_viewer), collection)

      expect(GrdaWarehouse::Cohort.editable_by(acl_user).pluck(:id)).to be_empty
    end

    it 'excludes a cohort whose granting role has only feature permissions and no edit permission' do
      role = create(
        :cohort_client_viewer,
        can_configure_cohorts: true,
        can_add_cohort_clients: true,
        can_manage_inactive_cohort_clients: true,
      )
      setup_access_control(acl_user, role, collection)

      expect(GrdaWarehouse::Cohort.editable_by(acl_user).pluck(:id)).to be_empty
    end
  end

  describe '#owner_name' do
    context 'when no owner is assigned' do
      it 'returns Unassigned by default' do
        expect(cohort.owner_name).to eq('Unassigned')
      end

      it 'returns nil when include_unassigned is false' do
        expect(cohort.owner_name(include_unassigned: false)).to be_nil
      end
    end

    context 'when an owner is assigned' do
      before { cohort.update!(owner_id: user.id) }

      it 'returns the owner name' do
        expect(cohort.owner_name).to eq(user.name)
      end
    end
  end

  describe '#available_owners' do
    let!(:non_system_user) { create :acl_user }

    context 'via ACL path' do
      before do
        cohort_collection.set_viewables({ cohorts: [cohort.id] })
        setup_access_control(non_system_user, cohort_viewer, cohort_collection)
      end

      it 'includes users with ACL-based access to the cohort' do
        expect(cohort.available_owners).to include(non_system_user)
      end

      it 'does not include users with no access' do
        other_user = create(:acl_user)
        expect(cohort.available_owners).not_to include(other_user)
      end
    end

    context 'via legacy access group path' do
      let!(:access_group) { create :access_group }

      before do
        access_group.set_viewables({ cohorts: [cohort.id] })
        access_group.add(non_system_user)
      end

      it 'includes users with legacy access-group-based access to the cohort' do
        expect(cohort.available_owners).to include(non_system_user)
      end
    end

    context 'when current owner has no access to the cohort' do
      let!(:owner_without_access) { create :acl_user }

      before { cohort.update!(owner_id: owner_without_access.id) }

      it 'still includes the current owner' do
        expect(cohort.available_owners).to include(owner_without_access)
      end
    end
  end

  describe 'column_state handling' do
    let!(:test_column) { build :user_string_cohort_column_1 }

    before do
      # Add test column to cohort's column_state
      @all_columns = GrdaWarehouse::Cohort.available_columns
      # Activate via a separate lookup rather than calling `.cohort_column.activate` on the same
      # instances assigned to column_state below: CohortColumns::Base#cohort_column memoizes a
      # live GrdaWarehouse::Cohorts::CohortColumn (an ActiveRecord instance) onto `@cohort_column`,
      # which would then get embedded in this column's serialized YAML — real production writes
      # (Cohorts::ColumnsController#update) never do this; they only ever set `visible`/`editable`
      # directly on fresh instances, so this is a test-only artifact worth avoiding rather than a
      # real serialization need.
      GrdaWarehouse::Cohorts::CohortColumn.where(class_name: @all_columns.map(&:class_name)).find_each(&:activate)
      cohort.update(column_state: @all_columns)
    end

    it 'removes inactive columns from column_state' do
      expect(cohort.column_state.map(&:class_name)).to match_array(@all_columns.map(&:class_name))
      expect(cohort.reload.column_state.map(&:class_name)).to include('CohortColumns::UserString1')

      test_column.cohort_column.deactivate

      expect(cohort.reload.column_state.map(&:class_name)).to match_array(@all_columns.map(&:class_name) - ['CohortColumns::UserString1'])
      expect(cohort.reload.column_state.map(&:class_name)).not_to include('CohortColumns::UserString1')
    end

    it 'preserves active columns in column_state' do
      expect(cohort.column_state.map(&:class_name)).to match_array(@all_columns.map(&:class_name))
      expect(cohort.column_state.map(&:class_name)).to include('CohortColumns::UserString1')

      test_column.cohort_column.activate

      expect(cohort.column_state.map(&:class_name)).to match_array(@all_columns.map(&:class_name))
      expect(cohort.reload.column_state.map(&:class_name)).to include('CohortColumns::UserString1')
    end
  end

  describe 'column_state permitted-classes allow-list' do
    it 'round-trips a real CohortColumns instance from the known registry' do
      cohort.update!(column_state: [CohortColumns::LastName.new])

      expect(cohort.reload.column_state.map(&:class)).to eq([CohortColumns::LastName])
    end

    it 'rejects a class outside the known cohort columns allow-list' do
      malicious_yaml = "--- !ruby/object:Gem::Requirement\nrequirements: []\n"
      cohort.class.connection.execute(
        "UPDATE cohorts SET column_state = #{cohort.class.connection.quote(malicious_yaml)} WHERE id = #{cohort.id}",
      )

      expect { cohort.reload.column_state }.to raise_error(Psych::DisallowedClass)
    end
  end

  describe 'manager access' do
    let!(:manager_user) { create :acl_user }
    let!(:other_user) { create :acl_user }

    def fresh(user)
      User.clear_cached_permissions
      User.find(user.id)
    end

    it 'gives managers can_configure? on this cohort only' do
      cohort.replace_access([manager_user], scope: :manager)

      expect(fresh(manager_user).policy_for(cohort).can_configure?).to be true
      expect(fresh(manager_user).policy_for(cohort_2).can_configure?).to be false
      expect(fresh(other_user).policy_for(cohort).can_configure?).to be false
    end

    it 'removes managers who are no longer listed' do
      cohort.replace_access([manager_user, other_user], scope: :manager)
      cohort.replace_access([other_user], scope: :manager)

      expect(fresh(manager_user).policy_for(cohort).can_configure?).to be false
      expect(fresh(other_user).policy_for(cohort).can_configure?).to be true

      cohort.replace_access([], scope: :manager)

      expect(fresh(other_user).policy_for(cohort).can_configure?).to be false
    end

    it 'does not drop managers when the editors are replaced' do
      cohort.replace_access([manager_user], scope: :manager)
      cohort.replace_access([other_user], scope: :editor)

      expect(fresh(manager_user).policy_for(cohort).can_configure?).to be true
    end

    it 'uses a manager role that configures but does not create cohorts' do
      role = cohort.manager_role

      expect(role.can_configure_cohorts).to be true
      expect(role.can_create_cohorts).to be false
    end

    describe '#manager_user_ids' do
      it 'is empty when no manager group exists, without creating one' do
        expect { expect(cohort.manager_user_ids).to eq([]) }.not_to change(UserGroup, :count)
      end

      it 'returns the ids of this cohort\'s managers only' do
        cohort.replace_access([manager_user], scope: :manager)
        cohort_2.replace_access([other_user], scope: :manager)

        expect(cohort.manager_user_ids).to eq([manager_user.id])
      end
    end

    describe '#rename_manager_group' do
      it 'renames the existing manager group' do
        cohort.replace_access([manager_user], scope: :manager)
        cohort.update!(name: 'Renamed cohort')

        cohort.rename_manager_group

        expect(UserGroup.system.find_by(source: cohort, context: :manager).name).to eq('Renamed cohort [manager]')
      end

      it 'does nothing when there is no manager group' do
        cohort.update!(name: 'Renamed cohort')

        expect { cohort.rename_manager_group }.to not_change(UserGroup, :count).and not_change(AccessControl, :count)
      end
    end

    it 'leaves no user groups for a destroyed cohort' do
      cohort.replace_access([manager_user], scope: :manager)
      cohort.replace_access([other_user], scope: :editor)
      expect(UserGroup.where(source: cohort).count).to eq(2)

      cohort.destroy
      cohort.remove_system_collections!

      expect(UserGroup.where(source: cohort)).to be_empty
    end
  end

  describe '.listable_by' do
    let!(:view_only) { create :cohort }
    let!(:participate_only) { create :cohort }
    let!(:manager_only) { create :cohort }
    let!(:add_clients_only) { create :cohort }
    let!(:unrelated) { create :cohort }

    context 'with ACLs' do
      let!(:lister) { create :acl_user }

      before do
        {
          view_only => create(:role, can_view_cohorts: true),
          participate_only => create(:role, can_participate_in_cohorts: true),
          add_clients_only => create(:role, can_add_cohort_clients: true),
        }.each do |c, role|
          collection = create(:collection, collection_type: 'Cohorts')
          collection.set_viewables({ cohorts: [c.id] })
          setup_access_control(lister, role, collection)
        end
        manager_only.replace_access([lister], scope: :manager)
      end

      it 'includes view, participate and manager cohorts and excludes the rest' do
        ids = described_class.listable_by(User.find(lister.id)).pluck(:id)

        expect(ids).to contain_exactly(view_only.id, participate_only.id, manager_only.id)
      end
    end

    context 'with legacy permissions' do
      let!(:legacy_user) { create :user }

      def grant(user, role, *cohorts)
        user.legacy_roles << role
        access_group = create(:access_group)
        access_group.add(user)
        cohorts.each { |c| access_group.add_viewable(c) }
      end

      it 'lists the access-group cohorts when a role has a view flag' do
        grant(legacy_user, create(:role, can_view_cohorts: true), view_only, participate_only)

        ids = described_class.listable_by(User.find(legacy_user.id)).pluck(:id)

        expect(ids).to contain_exactly(view_only.id, participate_only.id)
      end

      it 'lists the access-group cohorts when a role only configures cohorts' do
        grant(legacy_user, create(:role, can_configure_cohorts: true), manager_only)

        expect(described_class.listable_by(User.find(legacy_user.id)).pluck(:id)).to eq([manager_only.id])
      end

      it 'lists nothing when the roles carry only add-clients' do
        grant(legacy_user, create(:role, can_add_cohort_clients: true), add_clients_only)

        expect(described_class.listable_by(User.find(legacy_user.id)).pluck(:id)).to be_empty
      end
    end

    it 'is empty without a user' do
      expect(described_class.listable_by(nil)).to be_empty
    end
  end

  describe 'default_sort_direction validation' do
    it 'accepts each defined sort direction' do
      GrdaWarehouse::Cohort.sort_directions.each_key do |direction|
        expect(build(:cohort, default_sort_direction: direction)).to be_valid
      end
    end

    it 'accepts a blank sort direction' do
      expect(build(:cohort, default_sort_direction: '')).to be_valid
    end

    it 'rejects a value that is not a defined sort direction' do
      record = build(:cohort, default_sort_direction: 'sideways')

      expect(record).not_to be_valid
      expect(record.errors[:default_sort_direction]).to eq(['is not included in the list'])
    end
  end
end
