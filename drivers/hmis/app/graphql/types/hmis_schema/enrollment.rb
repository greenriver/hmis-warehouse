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
    include Types::HmisSchema::HasCustomCaseNotes
    include Types::HmisSchema::HasFiles
    include Types::HmisSchema::HasIncomeBenefits
    include Types::HmisSchema::HasDisabilities
    include Types::HmisSchema::HasHealthAndDvs
    include Types::HmisSchema::HasYouthEducationStatuses
    include Types::HmisSchema::HasEmploymentEducations
    include Types::HmisSchema::HasCurrentLivingSituations
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::Enrollment.hmis_configuration(version: '2024')
    end

    # Special field function to perform field-level authorization, to ensure that user has Detail-level access to this Enrollment.
    # If user lacks sufficient access, field is resolved as null. See Types::BaseField `authorized?` function.
    def self.detail_field(name, type = nil, **kwargs)
      field(name, type, **kwargs, permission: :can_view_enrollment_details)
    end

    available_filter_options do
      arg :status, [HmisSchema::Enums::EnrollmentFilterOptionStatus]
      arg :open_on_date, GraphQL::Types::ISO8601Date
      arg :bed_night_on_date, GraphQL::Types::ISO8601Date
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :search_term, String
    end

    description 'HUD Enrollment'

    # LIMITED ACCESS FIELDS. These fields are visible with `can_view_limited_enrollment_details` permission (or `can_view_enrollment_details` + `can_view_project` perms).
    field :id, ID, null: false
    field :lock_version, Integer, null: false
    field :project_name, String, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    field :organization_name, String, null: false
    field :entry_date, GraphQL::Types::ISO8601Date, null: false
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    field :status, HmisSchema::Enums::EnrollmentStatus, null: false
    field :client, HmisSchema::Client, null: false
    field :in_progress, Boolean, null: false
    field :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, null: false, default_value: 99

    # DETAILED ACCESS FIELDS. These fields are visible with `can_view_enrollment_details` + `can_view_project` permissions.
    # For non-nullable fields, an error will be thrown if the client tries to query them for a Limited-access enrollment.
    # For nullable fields, they will be resolved as null for Limited-access enrollments.
    detail_field :project, Types::HmisSchema::Project, null: false
    detail_field :exit_destination, Types::HmisSchema::Enums::Hud::Destination, null: true
    detail_field :household_id, ID, null: false
    detail_field :household_short_id, ID, null: false
    detail_field :household, HmisSchema::Household, null: false
    detail_field :household_size, Integer, null: false
    # Associated records (detail-access)
    assessments_field permission: :can_view_enrollment_details
    events_field permission: :can_view_enrollment_details
    services_field filter_args: { omit: [:project, :project_type], type_name: 'ServicesForEnrollment' }, permission: :can_view_enrollment_details
    custom_case_notes_field permission: :can_view_enrollment_details
    files_field permission: :can_view_enrollment_details
    ce_assessments_field permission: :can_view_enrollment_details
    income_benefits_field permission: :can_view_enrollment_details
    disabilities_field permission: :can_view_enrollment_details
    health_and_dvs_field permission: :can_view_enrollment_details
    youth_education_statuses_field permission: :can_view_enrollment_details
    employment_educations_field permission: :can_view_enrollment_details
    current_living_situations_field permission: :can_view_enrollment_details
    custom_data_elements_field permission: :can_view_enrollment_details
    # 3.16.1
    detail_field :enrollment_coc, String, null: true
    # 3.08
    detail_field :disabling_condition, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true, default_value: 99
    # 3.13.1
    detail_field :date_of_engagement, GraphQL::Types::ISO8601Date, null: true
    # 3.20.1
    detail_field :move_in_date, GraphQL::Types::ISO8601Date, null: true
    # 3.917
    detail_field :living_situation, HmisSchema::Enums::Hud::PriorLivingSituation
    detail_field :rental_subsidy_type, Types::HmisSchema::Enums::Hud::RentalSubsidyType
    detail_field :length_of_stay, HmisSchema::Enums::Hud::ResidencePriorLengthOfStay
    detail_field :los_under_threshold, HmisSchema::Enums::Hud::NoYesMissing
    detail_field :previous_street_essh, HmisSchema::Enums::Hud::NoYesMissing
    detail_field :date_to_street_essh, GraphQL::Types::ISO8601Date
    detail_field :times_homeless_past_three_years, HmisSchema::Enums::Hud::TimesHomelessPastThreeYears
    detail_field :months_homeless_past_three_years, HmisSchema::Enums::Hud::MonthsHomelessPastThreeYears
    # P3
    detail_field :date_of_path_status, GraphQL::Types::ISO8601Date, null: true
    detail_field :client_enrolled_in_path, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :reason_not_enrolled, HmisSchema::Enums::Hud::ReasonNotEnrolled, null: true
    # V4
    detail_field :percent_ami, HmisSchema::Enums::Hud::PercentAMI, null: true
    # R1
    detail_field :referral_source, HmisSchema::Enums::Hud::ReferralSource, null: true
    detail_field :count_outreach_referral_approaches, Integer, null: true
    # R2
    detail_field :date_of_bcp_status, GraphQL::Types::ISO8601Date, null: true
    detail_field :eligible_for_rhy, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :reason_no_services, HmisSchema::Enums::Hud::ReasonNoServices, null: true
    detail_field :runaway_youth, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    # R3
    detail_field :sexual_orientation, HmisSchema::Enums::Hud::SexualOrientation, null: true
    detail_field :sexual_orientation_other, String, null: true
    # R11
    detail_field :former_ward_child_welfare, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    detail_field :child_welfare_years, HmisSchema::Enums::Hud::RHYNumberofYears, null: true
    detail_field :child_welfare_months, Integer, null: true
    # R12
    detail_field :former_ward_juvenile_justice, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    detail_field :juvenile_justice_years, HmisSchema::Enums::Hud::RHYNumberofYears, null: true
    detail_field :juvenile_justice_months, Integer, null: true
    # R13
    detail_field :unemployment_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :mental_health_disorder_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :physical_disability_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :alcohol_drug_use_disorder_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :insufficient_income, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :incarcerated_parent, HmisSchema::Enums::Hud::NoYesMissing, null: true
    # V6
    detail_field :vamc_station, HmisSchema::Enums::Hud::VamcStationNumber, null: true
    # V7
    detail_field :target_screen_reqd, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :time_to_housing_loss, HmisSchema::Enums::Hud::TimeToHousingLoss, null: true
    detail_field :annual_percent_ami, HmisSchema::Enums::Hud::AnnualPercentAMI, null: true
    detail_field :literal_homeless_history, HmisSchema::Enums::Hud::LiteralHomelessHistory, null: true
    detail_field :client_leaseholder, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :hoh_leaseholder, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :subsidy_at_risk, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :eviction_history, HmisSchema::Enums::Hud::EvictionHistory, null: true
    detail_field :criminal_record, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :incarcerated_adult, HmisSchema::Enums::Hud::IncarceratedAdult, null: true
    detail_field :prison_discharge, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :sex_offender, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :disabled_hoh, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :current_pregnant, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :single_parent, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :dependent_under6, HmisSchema::Enums::Hud::DependentUnder6, null: true
    detail_field :hh5_plus, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :coc_prioritized, HmisSchema::Enums::Hud::NoYesMissing, null: true
    detail_field :hp_screening_score, Integer, null: true
    detail_field :threshold_score, Integer, null: true
    # C4
    detail_field :translation_needed, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    detail_field :preferred_language, HmisSchema::Enums::Hud::PreferredLanguage, null: true
    detail_field :preferred_language_different, String, null: true

    detail_field :intake_assessment, HmisSchema::Assessment, null: true
    detail_field :exit_assessment, HmisSchema::Assessment, null: true
    access_field do
      can :view_enrollment_details
      can :edit_enrollments
      can :delete_enrollments
      can :split_households
    end

    detail_field :current_unit, HmisSchema::Unit, null: true
    detail_field :num_units_assigned_to_household, Integer, null: false, default_value: 0
    detail_field :reminders, [HmisSchema::Reminder], null: false
    detail_field :open_enrollment_summary, [HmisSchema::EnrollmentSummary], null: false
    detail_field :last_bed_night_date, GraphQL::Types::ISO8601Date, null: true

    def open_enrollment_summary
      return [] unless current_user.can_view_open_enrollment_summary_for?(object)

      client = load_ar_association(object, :client)
      load_ar_association(client, :enrollments).where.not(id: object.id).open_including_wip
    end

    def reminders
      # assumption is this is called on a single record; we aren't solving n+1 queries
      project = object.project
      enrollments = project.enrollments_including_wip.where(household_id: object.HouseholdID)
      Hmis::Reminders::ReminderGenerator.perform(project: project, enrollments: enrollments)
    end

    def last_bed_night_date
      return unless project.project_type == 1

      load_ar_association(object, :bed_nights).map(&:date_provided).max
    end

    def project
      if object.in_progress?
        wip = load_ar_association(object, :wip)
        load_ar_association(wip, :project)
      else
        load_ar_association(object, :project)
      end
    end

    # Independent ProjectName field is needed because limited access viewers cannot resolve the project
    def project_name
      project&.project_name
    end

    # Independent ProjectType field is needed because limited access viewers cannot resolve the project
    def project_type
      project&.project_type
    end

    # Independent OrganizationName field is needed because limited access viewers cannot resolve the project
    def organization_name
      load_ar_association(project, :organization).organization_name
    end

    def exit_date
      exit&.exit_date
    end

    def exit_destination
      exit&.destination
    end

    def exit
      load_ar_association(object, :exit)
    end

    def status
      Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(object)
    end

    def client
      load_ar_association(object, :client)
    end

    def household_short_id
      Hmis::Hud::Household.short_id(object.household_id)
    end

    def household
      load_ar_association(object, :household)
    end

    def household_size
      load_ar_association(household, :enrollments).map(&:personal_id).uniq.size
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
      resolve_assessments(**args)
    end

    def ce_assessments(**args)
      resolve_ce_assessments(**args)
    end

    def custom_case_notes(...)
      resolve_custom_case_notes(...)
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

    def current_unit
      load_ar_association(object, :current_unit)
    end

    # ALERT: n+1, dont use when resolving multiple enrollments
    def num_units_assigned_to_household
      object.household_members.
        map { |hhm| hhm.current_unit&.id }.
        compact.uniq.size
    end
  end
end
