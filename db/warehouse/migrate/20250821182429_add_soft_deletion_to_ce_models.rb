###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSoftDeletionToCeModels < ActiveRecord::Migration[7.1]
  def change
    [
      :hmis_unit_occupancy,
      :hmis_unit_types,
      :ce_referral_notes,
      :ce_custom_referral_statuses,
      :ce_referrals,
      :ce_match_rules,
      :ce_opportunities,
      :wfd_templates,
      :wfd_nodes,
      :wfd_flows,
      :wfe_steps,
      :wfe_instances,
      :wfe_step_assignments,
    ].each do |table|
      add_column table, :deleted_at, :datetime
      add_index :ce_opportunities, :deleted_at, name: "idx_#{table}_deleted_at"
    end
  end
end
