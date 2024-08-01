###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CurrentLivingSituation < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata
    include Types::HmisSchema::HasCustomDataElements

    def self.configuration
      Hmis::Hud::CurrentLivingSituation.hmis_configuration(version: '2024')
    end

    description 'HUD Current Living Situation'

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    field :verified_by_project_id, ID, null: true
    hud_field :current_living_situation, HmisSchema::Enums::Hud::CurrentLivingSituation, default_value: 99
    hud_field :verified_by
    hud_field :cls_subsidy_type, HmisSchema::Enums::Hud::RentalSubsidyType
    hud_field :leave_situation14_days, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :subsequent_residence, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :resources_to_obtain, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :lease_own60_day, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :moved_two_or_more, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :location_details

    custom_data_elements_field

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
