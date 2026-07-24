# frozen_string_literal: true

class AddCandidatesFullyGeneratedAtToCeMatchCandidatePools < ActiveRecord::Migration[7.2]
  def up
    add_column :ce_match_candidate_pools, :candidates_fully_generated_at, :datetime

    # Backfill: treat any prior generated_at timestamp as evidence a full processing run has happened
    safety_assured do
      execute <<~SQL.squish
        UPDATE ce_match_candidate_pools
        SET candidates_fully_generated_at = candidates_generated_at
        WHERE candidates_generated_at IS NOT NULL
      SQL
    end
  end

  def down
    remove_column :ce_match_candidate_pools, :candidates_fully_generated_at
  end
end
