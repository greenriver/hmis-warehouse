###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Disability < Types::BaseObject
    def self.configuration
      Hmis::Hud::Disability.hmis_configuration(version: '2024')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    field :disability_type, HmisSchema::Enums::Hud::DisabilityType, null: false, default_value: Types::BaseEnum::INVALID_VALUE
    hud_field :disability_response, HmisSchema::Enums::Hud::DisabilityResponse
    hud_field :indefinite_and_impairs
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: true, default_value: Types::BaseEnum::INVALID_VALUE
    hud_field :t_cell_count_available, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    hud_field :t_cell_count, Integer, null: true
    hud_field :t_cell_source, HmisSchema::Enums::Hud::TCellSourceViralLoadSource, null: true
    hud_field :viral_load_available, HmisSchema::Enums::Hud::ViralLoadAvailable, null: true
    hud_field :viral_load, Integer, null: true
    hud_field :anti_retroviral, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

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
