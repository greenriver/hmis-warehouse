###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# health and domestic violence
module GrdaWarehouse::Hud
  class HealthAndDv < Base
    include HudSharedScopes
    include ::HMIS::Structure::HealthAndDv
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'HealthAndDV'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :health_and_dvs, optional: true
    has_one :client, through: :enrollment, inverse_of: :health_and_dvs
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_health_and_dvs, optional: true
    has_one :project, through: :enrollment
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :health_and_dvs, optional: true
    has_one :destination_client, through: :client
    belongs_to :data_source

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end

    scope :currently_fleeing, -> do
      where(CurrentlyFleeing: 1)
    end
  end
end
