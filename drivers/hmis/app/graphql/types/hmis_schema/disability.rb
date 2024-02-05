###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Disability < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::Disability.hmis_configuration(version: '2024')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    field :disability_type, HmisSchema::Enums::Hud::DisabilityType, null: false, default_value: Types::BaseEnum::INVALID_VALUE
    field :disability_response, HmisSchema::Enums::CompleteDisabilityResponse, null: false, default_value: 99
    field :indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false, default_value: Types::BaseEnum::INVALID_VALUE
    hud_field :t_cell_count_available, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    hud_field :t_cell_count, Integer, null: true
    hud_field :t_cell_source, HmisSchema::Enums::Hud::TCellSourceViralLoadSource, null: true
    hud_field :viral_load_available, HmisSchema::Enums::Hud::ViralLoadAvailable, null: true
    hud_field :viral_load, Integer, null: true
    hud_field :anti_retroviral, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def disability_response
      # Special case for Substance Use "1" which means Alcohol Use Disorder (as opposed to 'Yes' for others)
      if object.substance_use_type? && object.disability_response == 1
        Types::HmisSchema::Enums::CompleteDisabilityResponse::SUBSTANCE_USE_1_OVERRIDE_VALUE
      else
        object.disability_response
      end
    end
  end
end
