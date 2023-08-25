###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::YouthEducationStatus < Types::BaseObject
    def self.configuration
      Hmis::Hud::YouthEducationStatus.hmis_configuration(version: '2022')
    end

    description 'HUD Youth Education Status'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :user, HmisSchema::User, null: true
    field :client, HmisSchema::Client, null: false
    hud_field :information_date
    hud_field :current_school_attend, HmisSchema::Enums::Hud::CurrentSchoolAttended
    hud_field :most_recent_ed_status, HmisSchema::Enums::Hud::MostRecentEdStatus
    hud_field :current_ed_status, HmisSchema::Enums::Hud::CurrentEdStatus
    hud_field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage
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
