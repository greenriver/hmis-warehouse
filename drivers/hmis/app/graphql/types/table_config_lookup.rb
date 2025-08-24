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

    # Unit group waitlists- really these should be configured at Project Type level ideally
    def unit_group_waitlist(unit_group_id:)
      unit_group = Hmis::UnitGroup.find_by(id: unit_group_id)
      return unless unit_group

      Hmis::TableConfiguration.for_ce_waitlist.find_by(
        data_source_id: current_user.hmis_data_source_id,
        owner: unit_group,
      )
    end
  end
end
