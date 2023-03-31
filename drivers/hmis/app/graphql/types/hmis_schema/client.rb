###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Client < Types::BaseObject
    include Types::HmisSchema::HasEnrollments
    include Types::HmisSchema::HasServices
    include Types::HmisSchema::HasIncomeBenefits
    include Types::HmisSchema::HasDisabilities
    include Types::HmisSchema::HasDisabilityGroups
    include Types::HmisSchema::HasHealthAndDvs
    include Types::HmisSchema::HasAssessments
    include Types::HmisSchema::HasFiles

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
    hud_field :name_data_quality, Types::HmisSchema::Enums::Hud::NameDataQuality
    hud_field :dob
    field :age, Int, null: true
    hud_field :dob_data_quality, Types::HmisSchema::Enums::Hud::DOBDataQuality
    hud_field :ssn
    hud_field :ssn_data_quality, Types::HmisSchema::Enums::Hud::SSNDataQuality
    field :gender, [Types::HmisSchema::Enums::Gender], null: false
    field :race, [Types::HmisSchema::Enums::Race], null: false
    hud_field :ethnicity, Types::HmisSchema::Enums::Hud::Ethnicity
    hud_field :veteran_status, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    field :pronouns, [String], null: false
    enrollments_field without_args: [:search_term]
    income_benefits_field
    disabilities_field
    disability_groups_field
    health_and_dvs_field
    assessments_field
    services_field
    files_field
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
    field :image, HmisSchema::ClientImage, null: true

    access_field do
      can :view_partial_ssn
      can :view_full_ssn
      can :view_dob
      can :view_enrollment_details
      can :edit_enrollments
      can :delete_enrollments
      can :manage_any_client_files
      can :manage_own_client_files
      can :view_any_nonconfidential_client_files
      can :view_any_confidential_client_files
    end

    def enrollments(**args)
      resolve_enrollments(**args)
    end

    def income_benefits(**args)
      resolve_income_benefits(**args)
    end

    def disabilities(**args)
      resolve_disabilities(**args)
    end

    def disability_groups(**args)
      resolve_disability_groups(**args)
    end

    def health_and_dvs(**args)
      resolve_health_and_dvs(**args)
    end

    def assessments(**args)
      resolve_assessments_including_wip(**args)
    end

    def services(**args)
      resolve_services(**args)
    end

    def files(**args)
      resolve_files(**args)
    end

    def pronouns
      object.pronouns&.split('|') || []
    end

    def gender
      selected_genders = ::HudUtility.gender_field_name_to_id.except(:GenderNone).select { |f| object.send(f).to_i == 1 }.values
      selected_genders << object.GenderNone if object.GenderNone
      selected_genders
    end

    def race
      selected_races = ::HudUtility.races.except('RaceNone').keys.select { |f| object.send(f).to_i == 1 }
      selected_races << object.RaceNone if object.RaceNone
      selected_races
    end

    def image
      return nil unless object.image&.download

      object.image
    end

    def user
      load_ar_association(object, :user)
    end

    def ssn
      return object.ssn if current_user.can_view_full_ssn_for?(object)
      return object&.ssn&.sub(/^.*?(\d{4})$/, 'XXXXX\1') if current_user.can_view_partial_ssn_for?(object)
    end

    def dob
      object.safe_dob(current_user)
    end
  end
end
