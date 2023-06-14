###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CurrentLivingSituation < Types::BaseObject
    def self.configuration
      Hmis::Hud::CurrentLivingSituation.hmis_configuration(version: '2022')
    end

    description 'HUD Current Living Situation'

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :user, HmisSchema::User, null: true
    field :client, HmisSchema::Client, null: false
    hud_field :information_date
    hud_field :current_living_situation, HmisSchema::Enums::Hud::LivingSituation
    # TODO(2024): field :rental_subsidy_type, 3.12.A list
    hud_field :verified_by
    hud_field :leave_situation14_days, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :subsequent_residence, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :resources_to_obtain, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :lease_own60_day, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :moved_two_or_more, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :location_details
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
