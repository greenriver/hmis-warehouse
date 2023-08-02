###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EmploymentEducation < Types::BaseObject
    def self.configuration
      Hmis::Hud::EmploymentEducation.hmis_configuration(version: '2022')
    end

    description 'HUD Employment Education'

    field :id, ID, null: false
    ar_field :enrollment, HmisSchema::Enrollment, null: false
    ar_field :user, HmisSchema::User, null: true
    ar_field :client, HmisSchema::Client, null: false
    hud_field :information_date
    hud_field :last_grade_completed, HmisSchema::Enums::Hud::LastGradeCompleted
    hud_field :school_status, HmisSchema::Enums::Hud::SchoolStatus
    hud_field :employed, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :employment_type, HmisSchema::Enums::Hud::EmploymentType
    hud_field :not_employed_reason, HmisSchema::Enums::Hud::NotEmployedReason
    hud_field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
  end
end
