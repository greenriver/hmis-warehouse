###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EmploymentEducation < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::EmploymentEducation.hmis_configuration(version: '2024')
    end

    description 'HUD Employment Education'

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    hud_field :last_grade_completed, HmisSchema::Enums::Hud::LastGradeCompleted
    hud_field :school_status, HmisSchema::Enums::Hud::SchoolStatus
    hud_field :employed, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :employment_type, HmisSchema::Enums::Hud::EmploymentType
    hud_field :not_employed_reason, HmisSchema::Enums::Hud::NotEmployedReason
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false, default_value: Types::BaseEnum::INVALID_VALUE

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
