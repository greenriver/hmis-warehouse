###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Tasks
  class SeedExternalDataSharingCdeDefinition
    include MaintenanceTaskInstrumentation

    def self.perform
      new.perform
    end

    def perform
      instrument_as_maintenance_task do |run|
        run.complete! if _perform
      end
    end

    def _perform
      # data_source is not semantically meaningful here, but Hmis::Hud::CustomDataElementDefinition requires it via belongs_to.
      data_source = GrdaWarehouse::DataSource.destination.first
      return false unless data_source

      Hmis::Hud::CustomDataElementDefinition.find_or_create_by!(
        key: ClientExternalDataSharing::EXTERNAL_DATA_SHARING_CDE_KEY,
        owner_type: GrdaWarehouse::Hud::Client.name,
      ) do |d|
        d.label = 'Exclude from External Data Sharing'
        d.field_type = 'boolean'
        d.repeats = false
        d.data_source = data_source
        d.UserID = User.system_user.id.to_s
      end

      true
    end
  end
end
