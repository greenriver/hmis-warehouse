# frozen_string_literal: true

class AddUnitGroupAssignmentTable < ActiveRecord::Migration[7.2]
  def change
    # records the history of which CE candidate pool a unit group was assigned to at a given time.
    create_table :ce_pool_unit_group_assignments do |t|
      t.references :unit_group, null: false, foreign_key: { to_table: :hmis_unit_groups }
      t.references :candidate_pool, null: false, foreign_key: { to_table: :ce_match_candidate_pools }
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: true
      t.timestamps
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260212154318
# rails db:migrate:down:warehouse VERSION=20260212154318
