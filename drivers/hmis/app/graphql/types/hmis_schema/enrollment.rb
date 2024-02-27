###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enrollment < Types::BaseObject
    EXCLUDED_KEYS_FOR_AUDIT = ['owner_type', 'enrollment_address_type', 'wip'].freeze

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
    include Types::HmisSchema::HasAuditHistory

    def self.configuration
      Hmis::Hud::Enrollment.hmis_configuration(version: '2024')
    end

    # check for the most minimal permission needed to resolve this object
    # (can_view_project AND can_view_enrollment_details) OR can_view_limited_enrollment_details
    def self.authorized?(object, ctx)
      return false unless super

      return true if GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: :can_view_limited_enrollment_details, entity: object)

      return false unless GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: :can_view_enrollment_details, entity: object)

      project = ctx.dataloader.with(Sources::ActiveRecordAssociation, :project).load(object)
      GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: :can_view_project, entity: project)
    end

    # Override the "field" function to perform field-level authorization.
    # If user lacks sufficient access, the field will be resolved as null.
    #
    # This is necessary because the user may have access to view
    # "full" enrollment details for some Enrollments, but only "limited" access
    # to other Enrollments.
    def self.field(name, type = nil, **kwargs)
      # See Types::BaseField `authorized?` function.
      super(name, type, permissions: :can_view_enrollment_details, **kwargs)
    end

    # Add a separate "field" function to use for summary fields which are visible
    # to users with "can_view_limited_enrollment_details".
    #
    # No field-level authorization is needed here, because the enrollment necessarily
    # has some level of visibility if it's being resolved.
    def self.summary_field(name, type = nil, **kwargs)
      field(name, type, **kwargs, permissions: nil)
    end

    available_filter_options do
      arg :status, [HmisSchema::Enums::EnrollmentFilterOptionStatus]
      arg :open_on_date, GraphQL::Types::ISO8601Date
      arg :bed_night_on_date, GraphQL::Types::ISO8601Date
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :household_tasks, [HmisSchema::Enums::EnrollmentFilterOptionHouseholdTask]
      arg :search_term, String
    end

    description 'HUD Enrollment'

    # SUMMARY FIELDS. These fields are visible with `can_view_limited_enrollment_details` permission.
    summary_field :id, ID, null: false
    summary_field :lock_version, Integer, null: false
    summary_field :project_name, String, null: false
    summary_field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    summary_field :organization_name, String, null: false
    summary_field :entry_date, GraphQL::Types::ISO8601Date, null: false
    summary_field :exit_date, GraphQL::Types::ISO8601Date, null: true
    summary_field :status, HmisSchema::Enums::EnrollmentStatus, null: false
    summary_field :client, HmisSchema::Client, null: false
    summary_field :in_progress, Boolean, null: false
    summary_field :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, null: false, default_value: 99
    summary_field :move_in_date, GraphQL::Types::ISO8601Date, null: true
    summary_field :last_bed_night_date, GraphQL::Types::ISO8601Date, null: true

    field :last_service_date, GraphQL::Types::ISO8601Date, null: true do
      argument :service_type_id, ID, required: true
    end
    # Override permission requirement for the access object. This is necessary so the frontend
    # knows whether its safe to link to the full enrollment dashboard for a given enrollment.
    access_field permissions: nil do
      can :view_enrollment_details
      can :edit_enrollments
      can :delete_enrollments
      can :split_households
      can :audit_enrollments
    end

    # FULL ACCESS FIELDS. All fields below this line require `can_view_enrollment_details` perm, because they use the overridden 'field' class method.
    field :project, Types::HmisSchema::Project, null: false
    field :exit_destination, Types::HmisSchema::Enums::Hud::Destination, null: true
    field :household_id, ID, null: false
    field :household_short_id, ID, null: false
    field :household, HmisSchema::Household, null: false
    field :household_size, Integer, null: false
    # Associated records. These automatically require the "can_view_enrollment_details" permission
    # because they use the overridden 'field' class method.
    assessments_field filter_args: { omit: [:project, :project_type], type_name: 'AssessmentsForEnrollment' }
    events_field
    services_field filter_args: { omit: [:project, :project_type], type_name: 'ServicesForEnrollment' }
    custom_case_notes_field
    files_field
    ce_assessments_field
    income_benefits_field
    disabilities_field
    health_and_dvs_field
    youth_education_statuses_field
    employment_educations_field
    current_living_situations_field
    field :assessment_eligibilities, [HmisSchema::AssessmentEligibility], null: false
    field :last_current_living_situation, Types::HmisSchema::CurrentLivingSituation, null: true
    custom_data_elements_field
    # 3.16.1
    field :enrollment_coc, String, null: true
    # 3.08
    field :disabling_condition, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true, default_value: 99
    # 3.13.1
    field :date_of_engagement, GraphQL::Types::ISO8601Date, null: true
    # 3.917
    field :living_situation, HmisSchema::Enums::Hud::PriorLivingSituation
    field :rental_subsidy_type, Types::HmisSchema::Enums::Hud::RentalSubsidyType
    field :length_of_stay, HmisSchema::Enums::Hud::ResidencePriorLengthOfStay
    field :los_under_threshold, HmisSchema::Enums::Hud::NoYesMissing
    field :previous_street_essh, HmisSchema::Enums::Hud::NoYesMissing
    field :date_to_street_essh, GraphQL::Types::ISO8601Date
    field :times_homeless_past_three_years, HmisSchema::Enums::Hud::TimesHomelessPastThreeYears
    field :months_homeless_past_three_years, HmisSchema::Enums::Hud::MonthsHomelessPastThreeYears
    # P3
    field :date_of_path_status, GraphQL::Types::ISO8601Date, null: true
    field :client_enrolled_in_path, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :reason_not_enrolled, HmisSchema::Enums::Hud::ReasonNotEnrolled, null: true
    # V4
    field :percent_ami, HmisSchema::Enums::Hud::PercentAMI, null: true
    # R1
    field :referral_source, HmisSchema::Enums::Hud::ReferralSource, null: true
    field :count_outreach_referral_approaches, Integer, null: true
    # R2
    field :date_of_bcp_status, GraphQL::Types::ISO8601Date, null: true
    field :eligible_for_rhy, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :reason_no_services, HmisSchema::Enums::Hud::ReasonNoServices, null: true
    field :runaway_youth, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    # R3
    field :sexual_orientation, HmisSchema::Enums::Hud::SexualOrientation, null: true
    field :sexual_orientation_other, String, null: true
    # R11
    field :former_ward_child_welfare, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :child_welfare_years, HmisSchema::Enums::Hud::RHYNumberofYears, null: true
    field :child_welfare_months, Integer, null: true
    # R12
    field :former_ward_juvenile_justice, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :juvenile_justice_years, HmisSchema::Enums::Hud::RHYNumberofYears, null: true
    field :juvenile_justice_months, Integer, null: true
    # R13
    field :unemployment_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :mental_health_disorder_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :physical_disability_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :alcohol_drug_use_disorder_fam, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :insufficient_income, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :incarcerated_parent, HmisSchema::Enums::Hud::NoYesMissing, null: true
    # V6
    field :vamc_station, HmisSchema::Enums::Hud::VamcStationNumber, null: true
    # V7
    field :target_screen_reqd, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :time_to_housing_loss, HmisSchema::Enums::Hud::TimeToHousingLoss, null: true
    field :annual_percent_ami, HmisSchema::Enums::Hud::AnnualPercentAMI, null: true
    field :literal_homeless_history, HmisSchema::Enums::Hud::LiteralHomelessHistory, null: true
    field :client_leaseholder, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :hoh_leaseholder, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :subsidy_at_risk, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :eviction_history, HmisSchema::Enums::Hud::EvictionHistory, null: true
    field :criminal_record, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :incarcerated_adult, HmisSchema::Enums::Hud::IncarceratedAdult, null: true
    field :prison_discharge, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :sex_offender, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :disabled_hoh, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :current_pregnant, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :single_parent, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :dependent_under6, HmisSchema::Enums::Hud::DependentUnder6, null: true
    field :hh5_plus, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :coc_prioritized, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :hp_screening_score, Integer, null: true
    field :threshold_score, Integer, null: true
    # C4
    field :translation_needed, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :preferred_language, HmisSchema::Enums::Hud::PreferredLanguage, null: true
    field :preferred_language_different, String, null: true

    field :intake_assessment, HmisSchema::Assessment, null: true
    field :exit_assessment, HmisSchema::Assessment, null: true
    field :current_unit, HmisSchema::Unit, null: true
    field :num_units_assigned_to_household, Integer, null: false, default_value: 0
    field :reminders, [HmisSchema::Reminder], null: false
    field :open_enrollment_summary, [HmisSchema::EnrollmentSummary], null: false

    field :move_in_addresses, [HmisSchema::ClientAddress], null: false

    audit_history_field(
      :audit_history,
      # Fields should match our DB casing, consult schema to determine appropriate casing
      excluded_keys: Types::HmisSchema::Enrollment::EXCLUDED_KEYS_FOR_AUDIT,
      filter_args: { omit: [:client_record_type], type_name: 'EnrollmentAuditEvent' },
      # Transformation for Disability response type
      transform_changes: ->(version, changes) do
        return changes unless version.item_type == Hmis::Hud::Disability.sti_name
        return changes unless version.object_with_changes['DisabilityType'] == 10 # Substance Use

        # Override 1=>10 for SubstanceUse value, so it shows up as 'Alcohol Use Disorder' instead of 'Yes'
        # in the audit change summary component.
        if changes['DisabilityResponse']
          changes['DisabilityResponse'] = changes['DisabilityResponse'].map do |value|
            if value == 1
              Types::HmisSchema::Enums::CompleteDisabilityResponse::SUBSTANCE_USE_1_OVERRIDE_VALUE
            else
              value
            end
          end
        end

        changes
      end,
    )

    def last_service_date(service_type_id:)
      cst = Hmis::Hud::CustomServiceType.find(service_type_id)
      if cst.hud_record_type && cst.hud_type_provided
        load_ar_association(object, :services).map(&:DateProvided).max
      else
        load_ar_association(object, :custom_services).map(&:DateProvided).max
      end
    end

    def audit_history(filters: nil)
      scope = GrdaWarehouse.paper_trail_versions.
        where(enrollment_id: object.id).
        where.not(object_changes: nil, event: 'update').
        unscope(:order). # Unscope to remove default order, otherwise it will conflict
        order(created_at: :desc)
      Hmis::Filter::PaperTrailVersionFilter.new(filters).filter_scope(scope)
    end

    # Summary of ALL open enrollments that this client currently has.
    # This is different from the "summary_fields" which are governed by a different
    # permission ('can_view_limited_enrollment_details').
    def open_enrollment_summary
      return [] unless current_permission?(permission: :can_view_open_enrollment_summary, entity: object)

      client = load_ar_association(object, :client)
      # There is no "viewable_by" check on the enrollments, because this permission
      # grants full access regardless of enrollment/project visibility.
      load_ar_association(client, :enrollments).where.not(id: object.id).open_including_wip
    end

    def last_current_living_situation
      load_ar_association(object, :current_living_situations).max_by(&:information_date)
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

    # Needed because limited access viewers cannot resolve the project
    def project_name
      return Hmis::Hud::Project::CONFIDENTIAL_PROJECT_NAME if project&.confidential && !current_permission?(permission: :can_view_enrollment_details, entity: object)

      project&.project_name
    end

    # Needed because limited access viewers cannot resolve the project
    def project_type
      project&.project_type
    end

    # Needed because limited access viewers cannot resolve the project
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

    def assessment_eligibilities
      Hmis::EnrollmentAssessmentEligibilityList.new(enrollment: object)
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

    def move_in_addresses
      load_ar_association(object, :move_in_addresses)
    end
  end
end
