# frozen_string_literal: true

class AddUnitGroupAssignmentTable < ActiveRecord::Migration[7.2]
  def change
    # ce_pool_unit_group_assignments records the history of which CE candidate pool a unit group was assigned to at a given time.
    create_table :ce_pool_unit_group_assignments do |t|
      # Foreign key constraints for unit_group and candidate_pool are intentionally omitted,
      # to preserve historical records even if the unit group or candidate pool is deleted.
      t.references :unit_group, null: false, index: true
      t.references :candidate_pool, null: false, index: true

      t.datetime :started_at, null: false
      t.datetime :ended_at, null: true

      t.timestamps
    end

    add_index :ce_pool_unit_group_assignments, [:unit_group_id, :candidate_pool_id, :started_at], unique: true, name: 'index_ce_pool_unit_group_assignments_uniq'
  end
end

# rails db:migrate:up:warehouse VERSION=20260212154318
# rails db:migrate:down:warehouse VERSION=20260212154318
