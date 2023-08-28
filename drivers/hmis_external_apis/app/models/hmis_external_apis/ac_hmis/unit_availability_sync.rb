###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # Track local and synced changes
  class UnitAvailabilitySync < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_unit_availability_syncs'
    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :unit_type, class_name: 'Hmis::UnitType'
    belongs_to :user, class_name: 'Hmis::User'

    scope :dirty, -> { where(arel_table[:local_version].gt(arel_table[:synced_version])) }

    def self.upsert_or_bump_version(project_id:, user_id:, unit_type_id:)
      record = {
        project_id: project_id,
        user_id: user_id,
        unit_type_id: unit_type_id,
        local_version: 1,
      }
      import!(
        [record],
        validate: false,
        on_duplicate_key_update: {
          conflict_target: [:project_id, :unit_type_id],
          columns: "local_version = #{table_name}.local_version + 1, user_id = excluded.user_id",
        },
      )
    end
  end
end
