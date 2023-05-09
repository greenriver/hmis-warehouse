###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enrollment < Types::BaseObject
    include Types::HmisSchema::HasEvents
    include Types::HmisSchema::HasServices
    include Types::HmisSchema::HasAssessments
    include Types::HmisSchema::HasCeAssessments
    include Types::HmisSchema::HasFiles
    include Types::HmisSchema::HasIncomeBenefits
    include Types::HmisSchema::HasDisabilities
    include Types::HmisSchema::HasDisabilityGroups
    include Types::HmisSchema::HasHealthAndDvs

    def self.configuration
      Hmis::Hud::Enrollment.hmis_configuration(version: '2022')
    end

    description 'HUD Enrollment'
    field :id, ID, null: false
    field :project, Types::HmisSchema::Project, null: false
    hud_field :entry_date
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    field :status, HmisSchema::Enums::EnrollmentStatus, null: false
    assessments_field
    events_field
    services_field
    files_field
    ce_assessments_field
    income_benefits_field
    disabilities_field
    disability_groups_field
    health_and_dvs_field
    field :household, HmisSchema::Household, null: false
    field :household_size, Integer, null: false
    field :client, HmisSchema::Client, null: false
    hud_field :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, null: false
    field :living_situation, HmisSchema::Enums::Hud::LivingSituation
    hud_field :length_of_stay, HmisSchema::Enums::Hud::ResidencePriorLengthOfStay
    hud_field :los_under_threshold, HmisSchema::Enums::Hud::NoYesMissing
    hud_field :previous_street_essh, HmisSchema::Enums::Hud::NoYesMissing
    hud_field :date_to_street_essh
    hud_field :times_homeless_past_three_years, HmisSchema::Enums::Hud::TimesHomelessPastThreeYears
    hud_field :months_homeless_past_three_years, HmisSchema::Enums::Hud::MonthsHomelessPastThreeYears
    hud_field :disabling_condition, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    field :in_progress, Boolean, null: false
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
    field :intake_assessment, HmisSchema::Assessment, null: true
    field :exit_assessment, HmisSchema::Assessment, null: true
    access_field do
      can :edit_enrollments
      can :delete_enrollments
    end

    def project
      load_ar_association(object.in_progress? ? object.wip : object, :project)
    end

    def exit_date
      exit&.exit_date
    end

    def exit
      load_ar_association(object, :exit)
    end

    def status
      Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(object)
    end

    # def household
    #   return nil unless object.household_id.present?

    #   # Use viewable_by to filter by data source
    #   Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: object.household_id).preload(:client)
    # end

    def household_size
      object.household.household_size
      # return 1 unless object.household_id.present?

      # # Use viewable_by to filter by data source
      # Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: object.household_id).count
    end

    def in_progress
      object.in_progress?
    end

    def events(**args)
      resolve_events(**args)
    end

    def services(**args)
      resolve_services(**args)
    end

    def assessments(**args)
      resolve_assessments_including_wip(**args)
    end

    def ce_assessments(**args)
      resolve_ce_assessments(**args)
    end

    def files(**args)
      resolve_files(**args)
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

    def user
      load_ar_association(object, :user)
    end
  end
end
