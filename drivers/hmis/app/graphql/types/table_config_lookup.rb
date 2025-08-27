###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class TableConfigLookup < Types::BaseObject
    skip_activity_log

    field :consolidated_waitlist, Types::TableConfig, null: true
    field :unit_group_waitlist, Types::TableConfig, null: true do
      argument :unit_group_id, ID, required: true
    end

    # Consolidated waitlist uses the global configuration for ce_waitlist
    def consolidated_waitlist
      Hmis::TableConfiguration.for_ce_waitlist.find_by(
        data_source_id: current_user.hmis_data_source_id,
        owner: nil,
      )
    end

    def unit_group_waitlist(unit_group_id:)
      unit_group = Hmis::UnitGroup.find_by(id: unit_group_id)
      return unless unit_group

      # find applicable configuration for this unit group, preferring more specific owners
      [
        unit_group,
        unit_group.project,
        unit_group.project&.organization,
        nil,
      ].each do |owner|
        config = Hmis::TableConfiguration.for_ce_waitlist.find_by(owner: owner)
        return config if config
      end
    end
  end
end
