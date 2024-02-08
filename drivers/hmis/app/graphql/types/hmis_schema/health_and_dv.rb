###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HealthAndDv < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::HealthAndDv.hmis_configuration(version: '2024')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    hud_field :domestic_violence_survivor, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :when_occurred, HmisSchema::Enums::Hud::WhenDVOccurred
    hud_field :currently_fleeing, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :general_health_status, HmisSchema::Enums::Hud::HealthStatus
    hud_field :dental_health_status, HmisSchema::Enums::Hud::HealthStatus
    hud_field :mental_health_status, HmisSchema::Enums::Hud::HealthStatus
    hud_field :pregnancy_status, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :due_date
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false, default_value: Types::BaseEnum::INVALID_VALUE

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
