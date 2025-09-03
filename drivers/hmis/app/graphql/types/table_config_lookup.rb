###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class TableConfigLookup < Types::BaseObject
    skip_activity_log

    field :ce_clients_global_config, Types::TableConfig, null: true
    field :ce_clients_unit_group_config, Types::TableConfig, null: true do
      argument :unit_group_id, ID, required: true
    end

    # Consolidated waitlist uses the global configuration for ce_waitlist
    def ce_clients_global_config
      Hmis::TableConfiguration.for_ce_clients_table.find_by(
        data_source_id: current_user.hmis_data_source_id,
        owner: nil,
      )
    end

    def ce_clients_unit_group_config(unit_group_id:)
      unit_group = Hmis::UnitGroup.find_by(id: unit_group_id)
      return unless unit_group

      # find applicable configuration for this unit group, preferring more specific owners
      [
        unit_group,
        unit_group.project,
        unit_group.project&.organization,
        nil,
      ].each do |owner|
        config = Hmis::TableConfiguration.for_ce_clients_table.
          where(data_source_id: current_user.hmis_data_source_id).
          find_by(owner: owner)
        return config if config
      end
    end
  end
end
