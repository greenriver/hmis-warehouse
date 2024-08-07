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

    def verified_by_project_id
      # This is a bit of a hack, but it enables the desired behavior on the frontend dropdown of projects, which is:
      # 1. If the CLS has verified_by_project_id, the dropdown shows that project as the selected option.
      # 2. If verified_by exists but NOT verified_by_project_id, it's probably a migrated-in string value that may or
      #    may not correspond to a project ID in our DB. We want to display the value, since it's the currently saved data,
      #    but it isn't a selectable option from the dropdown.
      # 3. If neither verified_by_project_id nor verified_by exists on the CLS, then the dropdown is unselected.
      #    The user can only select from allowable project options; they can't input random text.
      # See the CurrentLivingSituationProcessor for more detailed comments about the reason to collect both fields.
      object.verified_by_project_id || object.verified_by
    end
  end
end
