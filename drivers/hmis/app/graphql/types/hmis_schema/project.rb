###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Project < Types::BaseObject
    include Types::HmisSchema::HasInventories
    include Types::HmisSchema::HasProjectCocs
    include Types::HmisSchema::HasFunders
    include Types::HmisSchema::HasEnrollments
    include Types::HmisSchema::HasUnits
    include Types::HmisSchema::HasHouseholds
    include Types::HmisSchema::HasReferralRequests
    include Types::HmisSchema::HasReferralPostings
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasServices
    include Types::HmisSchema::HasHmisParticipations
    include Types::HmisSchema::HasCeParticipations
    include Types::HmisSchema::HasHudMetadata
    include Types::HmisSchema::HasExternalFormSubmissions
    include Types::HmisSchema::HasAssessments
    include Types::HmisSchema::HasCurrentLivingSituations

    def self.configuration
      Hmis::Hud::Project.hmis_configuration(version: '2024')
    end

    # check for the most minimal permission needed to resolve this object
    def self.authorized?(object, ctx)
      permission = :can_view_project
      super && GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: permission, entity: object)
    end

    available_filter_options do
      arg :status, [
        Types::BaseEnum.generate_enum('ProjectFilterOptionStatus') do
          value 'OPEN', description: 'Open'
          value 'CLOSED', description: 'Closed'
        end,
      ]
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :funder, [HmisSchema::Enums::Hud::FundingSource]
      arg :organization, [ID]
      arg :search_term, String
    end

    hud_field :id, ID, null: false
    field :hud_id, ID, null: false
    hud_field :project_name
    hud_field :project_type, Types::HmisSchema::Enums::ProjectType
    hud_field :organization, Types::HmisSchema::Organization, null: false
    inventories_field
    project_cocs_field
    funders_field
    units_field
    external_form_submissions_field do
      argument :form_definition_identifier, ID, required: true
    end
    households_field
    hmis_participations_field
    ce_participations_field
    assessments_field filter_args: { omit: [:project, :project_type], type_name: 'AssessmentsForProject' }
    services_field filter_args: { omit: [:project, :project_type], type_name: 'ServicesForProject' }
    current_living_situations_field
    hud_field :operating_start_date, null: true
    hud_field :operating_end_date
    hud_field :description, String, null: true
    hud_field :contact_information, String, null: true
    hud_field :housing_type, Types::HmisSchema::Enums::Hud::HousingType
    field :rrh_sub_type, Types::HmisSchema::Enums::Hud::RRHSubType, null: true
    hud_field :target_population, HmisSchema::Enums::Hud::TargetPopulation
    hud_field :HOPWAMedAssistedLivingFac, HmisSchema::Enums::Hud::HOPWAMedAssistedLivingFac
    hud_field :continuum_project, HmisSchema::Enums::Hud::NoYes, null: true
    hud_field :residential_affiliation, HmisSchema::Enums::Hud::NoYes, null: true
    field :residential_affiliation_project_ids, [ID], null: false
    field :residential_affiliation_projects, [HmisSchema::Project], null: false
    field :affiliated_projects, [HmisSchema::Project], null: false
    field :active, Boolean, null: false
    enrollments_field filter_args: { omit: [:project_type], type_name: 'EnrollmentsForProject' }
    custom_data_elements_field
    referral_requests_field :referral_requests
    referral_postings_field :incoming_referral_postings
    referral_postings_field :outgoing_referral_postings
    access_field do
      can :delete_project
      can :edit_project_details
      can :view_partial_ssn
      can :view_full_ssn
      can :view_dob
      can :view_enrollment_details
      can :enroll_clients
      can :edit_enrollments
      can :delete_enrollments
      can :delete_assessments
      can :manage_inventory
      can :manage_incoming_referrals
      can :manage_outgoing_referrals
      can :manage_denied_referrals
      can :manage_external_form_submissions
    end
    field :unit_types, [Types::HmisSchema::UnitTypeCapacity], null: false
    field :has_units, Boolean, null: false

    field :data_collection_features, [Types::HmisSchema::DataCollectionFeature], null: false, description: 'Occurrence Point data collection features that are enabled for this Project (e.g. Current Living Situations, Events)'
    field :occurrence_point_forms, [Types::HmisSchema::OccurrencePointForm], null: false, method: :occurrence_point_form_instances, description: 'Forms for individual data elements that are collected at occurrence for this Project (e.g. Move-In Date)'
    field :service_types, [Types::HmisSchema::ServiceType], null: false, method: :available_service_types, description: 'Service types that are collected for this Project'

    def hud_id
      object.project_id
    end

    def enrollments(**args)
      check_enrollment_details_access

      resolve_enrollments(object.enrollments, dangerous_skip_permission_check: true, **args)
    end

    def assessments(**args)
      check_enrollment_details_access

      resolve_assessments(object.custom_assessments, dangerous_skip_permission_check: true, **args)
    end

    def current_living_situations(**args)
      check_enrollment_details_access

      resolve_assessments(object.current_living_situations, dangerous_skip_permission_check: true, **args)
    end

    def organization
      load_ar_association(object, :organization)
    end

    def inventories(**args)
      resolve_inventories(**args)
    end

    def services(**args)
      check_enrollment_details_access

      resolve_services(**args, dangerous_skip_permission_check: true)
    end

    def residential_affiliation_projects
      load_ar_association(object, :residential_projects)
    end

    def residential_affiliation_project_ids
      residential_affiliation_projects.map(&:id)
    end

    def affiliated_projects
      load_ar_association(object, :affiliated_projects)
    end

    # Build OpenStructs to resolve as UnitTypeCapacity
    def unit_types
      project_units = object.units
      capacity = project_units.group(:unit_type_id).count
      unoccupied = project_units.unoccupied_on.group(:unit_type_id).count

      object.units.map(&:unit_type).uniq.compact.map do |unit_type|
        OpenStruct.new(
          id: unit_type.id,
          unit_type: unit_type.description,
          capacity: capacity[unit_type.id] || 0,
          availability: unoccupied[unit_type.id] || 0,
        )
      end
    end

    # TODO use dataloader
    def units(**args)
      resolve_units(**args)
    end

    def has_units # rubocop:disable Naming/PredicateName
      load_ar_association(object, :units).exists?
    end

    def households(**args)
      check_enrollment_details_access

      resolve_households(object.households, **args, dangerous_skip_permission_check: true)
    end

    def referral_requests(**args)
      raise HmisErrors::ApiError, 'Access denied' unless current_permission?(entity: object, permission: :can_manage_incoming_referrals)

      scoped_referral_requests(object.external_referral_requests, **args)
    end

    # TODO(#186102846) support user-specified sorting/filtering
    def incoming_referral_postings(**args)
      raise HmisErrors::ApiError, 'Access denied' unless current_permission?(entity: object, permission: :can_manage_incoming_referrals)

      # Only show Active postings on the incoming referral table
      scoped_referral_postings(object.external_referral_postings.active, sort_order: :oldest_to_newest, **args)
    end

    def arel
      Hmis::ArelHelper.instance
    end

    # TODO(#186102846) support user-specified sorting/filtering
    def outgoing_referral_postings(**args)
      raise HmisErrors::ApiError, 'Access denied' unless current_permission?(entity: object, permission: :can_manage_outgoing_referrals)

      # Show all postings on the outgoing referral table
      scope = HmisExternalApis::AcHmis::ReferralPosting.
        joins(referral: :enrollment).
        where(arel.e_t[:ProjectID].eq(object.ProjectID))

      scoped_referral_postings(scope, sort_order: :relevent_status, **args)
    end

    def external_form_submissions(**args)
      instances = Hmis::Form::Instance.with_role(:EXTERNAL_FORM).active.where(entity: object)
      scope = HmisExternalApis::ExternalForms::FormSubmission.
        joins(:definition).
        where(definition: { identifier: instances.select(:definition_identifier) })

      form_definition_identifier = args.delete(:form_definition_identifier)
      scope = scope.where(definition: { identifier: form_definition_identifier }) if form_definition_identifier
      resolve_external_form_submissions(scope, **args)
    end

    private def check_enrollment_details_access
      # For resolving several associations, we want to skip permission checks that use the viewable_by scope, both for
      # performance reasons, and so that we throw an error instead of returning an empty list.
      # After this check it's OK to use `dangerous_skip_permission_check`
      raise 'access denied' unless current_user.can_view_enrollment_details_for?(object)
    end
  end
end
