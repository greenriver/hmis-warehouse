###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Client < Types::BaseObject
    include Types::HmisSchema::HasEnrollments

    def self.configuration
      Hmis::Hud::Client.hmis_configuration(version: '2022')
    end

    description 'HUD Client'
    field :id, ID, null: false
    hud_field :personal_id
    hud_field :first_name
    hud_field :middle_name
    hud_field :last_name
    field :preferred_name, String, null: true
    hud_field :name_suffix
    hud_field :name_data_quality, Types::HmisSchema::Enums::NameDataQuality
    hud_field :dob
    hud_field :dob_data_quality, Types::HmisSchema::Enums::DOBDataQuality
    hud_field :ssn
    hud_field :ssn_data_quality, Types::HmisSchema::Enums::SSNDataQuality
    field :gender, [Types::HmisSchema::Enums::Gender], null: false
    field :race, [Types::HmisSchema::Enums::Race], null: false
    hud_field :ethnicity, Types::HmisSchema::Enums::Ethnicity
    hud_field :veteran_status, Types::HmisSchema::Enums::YesNoMissingReason
    field :pronouns, String, null: true
    enrollments_field :enrollments, type: Types::HmisSchema::Enrollment.page_type
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    def enrollments(**args)
      resolve_enrollments(**args)
    end

    def gender
      selected_genders = ::HUD.gender_field_name_to_id.except(:GenderNone).select { |f| object.send(f).to_i == 1 }.values
      selected_genders << object.GenderNone if object.GenderNone
      selected_genders
    end

    def race
      selected_races = ::HUD.races.except('RaceNone').keys.select { |f| object.send(f).to_i == 1 }
      selected_races << object.RaceNone if object.RaceNone
      selected_races
    end
  end
end
