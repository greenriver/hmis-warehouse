# frozen_string_literal: true

class AddUnitGroupAssignmentTable < ActiveRecord::Migration[7.2]
  def change
    # records the history of which CE candidate pool a unit group was assigned to at a given time.
    # Foreign key constraints are intentionally omitted to preserve historical records even if the
    # unit group or candidate pool is deleted.
    create_table :ce_pool_unit_group_assignments do |t|
      t.references :unit_group, null: false, index: true
      t.references :candidate_pool, null: false, index: true
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: true
      t.timestamps
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260212154318
# rails db:migrate:down:warehouse VERSION=20260212154318
