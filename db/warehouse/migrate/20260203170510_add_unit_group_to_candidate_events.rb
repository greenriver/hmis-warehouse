# frozen_string_literal: true

class AddUnitGroupToCandidateEvents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # Add unit_group_id column (nullable initially for existing records)
    safety_assured do
      add_reference :ce_match_candidate_events, :unit_group, null: true, foreign_key: { to_table: :hmis_unit_groups }
    end

    # Make candidate_pool_id nullable (remove null: false constraint)
    change_column_null :ce_match_candidate_events, :candidate_pool_id, true

    # Add composite index for common query patterns
    add_index :ce_match_candidate_events, [:unit_group_id, :client_proxy_id, :created_at], name: 'index_ce_match_candidate_events_on_unit_group_client_created', algorithm: :concurrently
  end
end

# rails db:migrate:down:warehouse VERSION=20260203170510
# rails db:migrate:up:warehouse VERSION=20260203170510
