###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# health and domestic violence
module GrdaWarehouse::Hud
  class HealthAndDv < Base
    include HudSharedScopes
    include ::HmisStructure::HealthAndDv
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'HealthAndDV'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :health_and_dvs, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_health_and_dvs, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :health_and_dvs, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :health_and_dvs, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :client, through: :enrollment, inverse_of: :health_and_dvs
    has_one :project, through: :enrollment
    has_one :destination_client, through: :client

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end

    scope :currently_fleeing, -> do
      where(CurrentlyFleeing: 1)
    end

    scope :at_entry, -> do
      where(DataCollectionStage: 1)
    end

    scope :at_annual_update, -> do
      where(DataCollectionStage: 5)
    end
  end
end
