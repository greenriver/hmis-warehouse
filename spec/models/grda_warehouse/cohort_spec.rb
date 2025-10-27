###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      @all_columns = GrdaWarehouse::Cohort.available_columns
      @all_columns.each { |c| c.cohort_column.activate }
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

  describe 'automation filters' do
    include_context 'HUD enrollment builders'

    # The project_type needs to be one of the homeless project types for the sub-population filters to work correctly.
    # 1 is Emergency Shelter (Night-by-Night)
    let!(:project) { create_project(project_type: 1) }
    let!(:project_group) { create(:project_group, projects: [project]) }
    let(:cohort) { create(:cohort, project_group: project_group) }

    # Using instance variables because they are created in a before block
    # and need to be accessible in the `it` blocks.
    before do
      @client = create_client_with_warehouse_link
      @client_hoh = create_client_with_warehouse_link
      @client_veteran = create_client_with_warehouse_link(veteran_status: 1)

      create_enrollment(client: @client, project: project, entry_date: Date.current - 10.days, relationship_to_ho_h: 2)
      create_enrollment(client: @client_hoh, project: project, entry_date: Date.current - 10.days, relationship_to_ho_h: 1)
      create_enrollment(client: @client_veteran, project: project, entry_date: Date.current - 10.days, relationship_to_ho_h: 2)

      # Rebuild service history for all enrollments created so far.
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    end

    describe '.auto_maintained' do
      it 'includes cohorts with a project group' do
        expect { cohort.reload }.not_to(change { described_class.auto_maintained.include?(cohort) })
      end

      it 'includes cohorts with only a sub-population configured' do
        cohort.update!(project_group: nil, automation_sub_population: nil, automation_hoh_only: false)

        expect do
          cohort.update!(automation_sub_population: 'veterans')
        end.to change { described_class.auto_maintained.include?(cohort.reload) }.from(false).to(true)
      end

      it 'includes cohorts with only hoh_only set' do
        cohort.update!(project_group: nil, automation_sub_population: nil, automation_hoh_only: false)

        expect do
          cohort.update!(automation_hoh_only: true)
        end.to change { described_class.auto_maintained.include?(cohort.reload) }.from(false).to(true)
      end
    end

    describe '#build_automation_filter' do
      it 'builds a filter with the configured automation options' do
        cohort.update!(automation_sub_population: 'veterans', automation_hoh_only: true)

        filter = cohort.send(:build_automation_filter)

        expect(filter.project_group_ids).to eq([project_group.id])
        expect(filter.sub_population).to eq(:veterans)
        expect(filter.hoh_only).to be(true)
        expect(filter.require_service_during_range).to be(false)
      end
    end

    describe '#auto_maintained?' do
      it 'is true if project_group_id is set' do
        cohort.update!(project_group: project_group, automation_sub_population: nil, automation_hoh_only: false)
        expect(cohort).to be_auto_maintained
      end

      it 'is true if sub_population is set' do
        cohort.update!(project_group: nil, automation_sub_population: 'veterans', automation_hoh_only: false)
        expect(cohort).to be_auto_maintained
      end

      it 'is true if hoh_only is set' do
        cohort.update!(project_group: nil, automation_sub_population: nil, automation_hoh_only: true)
        expect(cohort).to be_auto_maintained
      end

      it 'is false if no automation is configured' do
        cohort.update!(project_group: nil, automation_sub_population: nil, automation_hoh_only: false)
        expect(cohort).not_to be_auto_maintained
      end
    end

    describe '#automation_scope_descriptions' do
      it 'includes the project group when present' do
        expect(cohort.automation_scope_descriptions).to include("projects in the #{project_group.name} project group")
      end

      it 'includes the sub-population label when present' do
        cohort.update!(automation_sub_population: 'veterans')
        expect(cohort.automation_scope_descriptions).to include('clients in the Veterans sub-population')
      end

      it 'includes heads of household when configured' do
        cohort.update!(automation_hoh_only: true)
        expect(cohort.automation_scope_descriptions).to include('clients who are Heads of Household')
      end
    end

    describe '#maintain' do
      it 'adds clients from project group' do
        cohort.maintain
        expect(cohort.clients.pluck(:id)).to contain_exactly(
          @client.destination_client.id,
          @client_hoh.destination_client.id,
          @client_veteran.destination_client.id,
        )
      end

      it 'filters by sub-population' do
        expect do
          cohort.update!(automation_sub_population: 'veterans')
          cohort.maintain
        end.to change { cohort.reload.automation_sub_population }.from(nil).to('veterans')

        expect(cohort.clients.pluck(:id)).to contain_exactly(@client_veteran.destination_client.id)
      end

      it 'filters by hoh_only' do
        expect do
          cohort.update!(automation_hoh_only: true)
          cohort.maintain
        end.to change { cohort.reload.automation_hoh_only }.from(false).to(true)

        expect(cohort.clients.pluck(:id)).to contain_exactly(@client_hoh.destination_client.id)
      end

      it 'filters by sub-population and hoh_only' do
        # Create a veteran HoH to test intersection
        client_vet_hoh = create_client_with_warehouse_link(veteran_status: 1)
        create_enrollment(client: client_vet_hoh, project: project, relationship_to_ho_h: 1, entry_date: Date.current - 10.days)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        expect do
          cohort.update!(automation_sub_population: 'veterans', automation_hoh_only: true)
          cohort.maintain
        end.to change { cohort.reload.automation_sub_population }.from(nil).to('veterans').
          and change { cohort.reload.automation_hoh_only }.from(false).to(true)

        expect(cohort.clients.pluck(:id)).to contain_exactly(client_vet_hoh.destination_client.id)
      end

      it 'removes clients no longer matching criteria' do
        cohort.maintain
        expect(cohort.clients.count).to eq(3)

        expect do
          cohort.update!(automation_hoh_only: true)
          cohort.maintain
        end.to change { cohort.reload.automation_hoh_only }.from(false).to(true)

        expect(cohort.clients.pluck(:id)).to contain_exactly(@client_hoh.destination_client.id)
      end
    end

    describe 'validations' do
      it 'allows valid sub_population' do
        cohort.automation_sub_population = 'veterans'
        expect(cohort).to be_valid
      end

      it 'rejects invalid sub_population' do
        cohort.automation_sub_population = 'invalid_pop'
        expect(cohort).not_to be_valid
        expect(cohort.errors[:automation_sub_population]).to include('is not a valid sub-population')
      end
    end
  end
end
