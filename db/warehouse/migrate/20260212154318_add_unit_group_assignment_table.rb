# frozen_string_literal: true

class AddUnitGroupAssignmentTable < ActiveRecord::Migration[7.2]
  def change
    # should be supported in RDS
    enable_extension 'btree_gist' unless extension_enabled?('btree_gist')

    create_table :ce_pool_unit_group_assignments do |t|
      # Foreign key constraints for unit_group and candidate_pool are intentionally omitted,
      # to preserve historical records even if the unit group or candidate pool is deleted.
      t.references :unit_group, null: false, index: true
      t.references :candidate_pool, null: false, index: true
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: true
      t.datetime :created_at, null: true
    end

    reversible do |dir|
      dir.up do
        # This constraint ensures that for a given unit_group_id, no two ranges [started_at, ended_at) overlap.
        # COALESCE(ended_at, 'infinity') handles the currently active assignment.
        safety_assured do
          execute <<~SQL
            ALTER TABLE ce_pool_unit_group_assignments
            ADD CONSTRAINT exclude_overlapping_unit_group_assignments
            EXCLUDE USING gist (
              unit_group_id WITH =,
              tsrange(started_at, COALESCE(ended_at, 'infinity'), '[)') WITH &&
            );
          SQL
        end
      end

      dir.down do
        safety_assured do
          execute <<~SQL
            ALTER TABLE ce_pool_unit_group_assignments
            DROP CONSTRAINT exclude_overlapping_unit_group_assignments;
          SQL
        end
      end
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260212154318
# rails db:migrate:down:warehouse VERSION=20260212154318
