###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class TableConfigLookup < Types::BaseObject
    skip_activity_log

    field :ce_clients_config, Types::TableConfig, null: true do
      argument :project_group_id, ID, required: false, description: 'Optional project group ID to use for detecting the best config. Falls back to global config if not provided, or if no project group config exists.'
    end

    field :ce_clients_global_config, Types::TableConfig, null: true

    field :ce_clients_unit_group_config, Types::TableConfig, null: true do
      argument :unit_group_id, ID, required: true
    end

    # Consolidated waitlist can use project-group configuration when scoped by a workspace.
    def ce_clients_config(project_group_id: nil)
      Hmis::TableConfiguration.detect_ce_clients_config(
        data_source_id: current_user.hmis_data_source_id,
        project_group_id: project_group_id,
      )
    end

    # Backwards-compatible global configuration lookup for ce_waitlist
    def ce_clients_global_config
      Hmis::TableConfiguration.detect_ce_clients_global_config(
        data_source_id: current_user.hmis_data_source_id,
      )
    end

    def ce_clients_unit_group_config(unit_group_id:)
      Hmis::TableConfiguration.detect_ce_clients_unit_group_config(
        data_source_id: current_user.hmis_data_source_id,
        unit_group_id: unit_group_id,
      )
    end
  end
end
