###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::YouthEducationStatus < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::YouthEducationStatus.hmis_configuration(version: '2024')
    end

    description 'HUD Youth Education Status'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    hud_field :current_school_attend, HmisSchema::Enums::Hud::CurrentSchoolAttended
    hud_field :most_recent_ed_status, HmisSchema::Enums::Hud::MostRecentEdStatus
    hud_field :current_ed_status, HmisSchema::Enums::Hud::CurrentEdStatus
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false, default_value: Types::BaseEnum::INVALID_VALUE

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
