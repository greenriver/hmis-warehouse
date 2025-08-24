###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSoftDeletionToCeModels < ActiveRecord::Migration[7.1]
  def up
    # rebuilding indexes on these small tables is safe
    safety_assured do
      tables.each do |table|
        add_column table, :deleted_at, :datetime
        # dedicated indexes are probably not needed for these tables. Add them later if there are
        # performance issues
        # add_index table, :deleted_at, name: "idx_#{table}_deleted_at"
      end

      # Adjust unique indexes to respect soft deletion by scoping to non-deleted rows
      unique_indexes.each do |spec|
        remove_index spec[:table], name: spec[:name]
        where_clause = [spec[:original_where], 'deleted_at IS NULL'].compact.join(' AND ')
        add_index spec[:table], spec[:columns], unique: true, where: where_clause, name: spec[:name]
      end
    end
  end

  def down
    # rebuilding indexes on these small tables is safe
    safety_assured do
      # Revert unique indexes back to their original definitions (without deleted_at guards)
      unique_indexes.each do |spec|
        remove_index spec[:table], name: spec[:name]
        if spec[:original_where].present?
          add_index spec[:table], spec[:columns], unique: true, where: spec[:original_where], name: spec[:name]
        else
          add_index spec[:table], spec[:columns], unique: true, name: spec[:name]
        end
      end

      # Remove simple deleted_at indexes and columns
      tables.each do |table|
        # remove_index table, name: "idx_#{table}_deleted_at"
        remove_column table, :deleted_at
      end
    end
  end

  private

  def tables
    [
      :hmis_unit_occupancy,
      :hmis_unit_types,
      :ce_referral_notes,
      :ce_custom_referral_statuses,
      :ce_referrals,
      :ce_referral_participants,
      :ce_match_rules,
      :ce_opportunities,
      :wfd_templates,
      :wfd_nodes,
      :wfd_flows,
      :wfe_steps,
      :wfd_swimlanes,
      :wfe_instances,
      :wfe_step_assignments,
    ]
  end

  def unique_indexes
    [
      {
        table: :ce_custom_referral_statuses,
        name: 'index_ce_custom_referral_statuses_on_key_and_data_source_id',
        columns: [:key, :data_source_id],
        original_where: nil,
      },
      {
        table: :ce_match_rules,
        name: 'index_ce_match_rules_owner_priority_rank_unique',
        columns: [:owner_type, :owner_id, :priority_rank],
        original_where: "rule_type = 'priority_scheme'",
      },
      {
        table: :wfd_templates,
        name: 'index_templates_on_identifier_published',
        columns: [:identifier],
        original_where: "status = 'published'",
      },
      {
        table: :wfd_flows,
        name: 'index_wfd_flows_on_source_node_id_and_target_node_id',
        columns: [:source_node_id, :target_node_id],
        original_where: nil,
      },
      {
        table: :wfe_steps,
        name: 'index_wfe_steps_on_instance_id_and_node_id',
        columns: [:instance_id, :node_id],
        original_where: nil,
      },
      {
        table: :wfe_step_assignments,
        name: 'index_wfe_step_assignments_on_user_id_and_step_id',
        columns: [:user_id, :step_id],
        original_where: nil,
      },
    ]
  end
end
