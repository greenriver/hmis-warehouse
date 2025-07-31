###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddNumericPriorityScoresToCeMatchCandidates < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :ce_match_candidates, :priority_scores, :integer, array: true
    add_index :ce_match_candidates, :priority_scores, using: :btree, algorithm: :concurrently

    safety_assured { remove_column :ce_match_candidates, :priority_score, :integer }

    add_column :ce_match_rules, :rank, :integer
    add_index :ce_match_rules, [:owner_type, :owner_id, :rank], unique: true, name: 'index_ce_match_rules_owner_rank_unique', algorithm: :concurrently
  end
end
