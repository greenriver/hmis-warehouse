###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HealthAndDv < Types::BaseObject
    def self.configuration
      Hmis::Hud::HealthAndDv.hmis_configuration(version: '2022')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    hud_field :information_date
    hud_field :domestic_violence_victim, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :when_occurred, HmisSchema::Enums::Hud::WhenDVOccurred
    hud_field :currently_fleeing, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :general_health_status, HmisSchema::Enums::Hud::HealthStatus
    hud_field :dental_health_status, HmisSchema::Enums::Hud::HealthStatus
    hud_field :mental_health_status, HmisSchema::Enums::Hud::HealthStatus
    hud_field :pregnancy_status, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :life_value, HmisSchema::Enums::Hud::WellbeingAgreement
    hud_field :support_from_others, HmisSchema::Enums::Hud::WellbeingAgreement
    hud_field :bounce_back, HmisSchema::Enums::Hud::WellbeingAgreement
    hud_field :feeling_frequency, HmisSchema::Enums::Hud::FeelingFrequency
    hud_field :due_date
    hud_field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    # TODO ADD: source assessment

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
