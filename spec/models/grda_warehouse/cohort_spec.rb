###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

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

  describe 'column_state handling' do
    let!(:test_column) { build :user_string_cohort_column_1 }

    before do
      # Add test column to cohort's column_state
      columns = cohort.column_state || []
      test_column.column_type.activate
      columns << test_column
      cohort.update(column_state: columns)
    end

    it 'removes inactive columns from column_state' do
      expect(cohort.column_state.map(&:class_name)).to include('CohortColumns::UserString1')
      # binding.pry
      test_column.column_type.deactivate

      expect(cohort.reload.column_state.map(&:class_name)).not_to include('CohortColumns::UserString1')
    end

    it 'preserves active columns in column_state' do
      expect(cohort.column_state.map(&:class_name)).to include('CohortColumns::UserString1')

      test_column.column_type.activate

      expect(cohort.reload.column_state.map(&:class_name)).to include('CohortColumns::UserString1')
    end

    it 'handles multiple columns in column_state' do
      # Add another column
      another_column = build :user_string_cohort_column_2, cohort: cohort

      columns = cohort.column_state
      columns << another_column
      cohort.update(column_state: columns)

      expect(cohort.column_state.map(&:class_name)).to include('CohortColumns::UserString1', 'CohortColumns::UserString2')

      # Deactivate one column
      test_column.column_type.deactivate

      expect(cohort.reload.column_state.map(&:class_name)).to include('CohortColumns::UserString2')
      expect(cohort.reload.column_state.map(&:class_name)).not_to include('CohortColumns::UserString1')
    end
  end
end
