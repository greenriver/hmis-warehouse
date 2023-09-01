###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def self.configuration
      Hmis::Hud::Project.hmis_configuration(version: '2024')
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
    households_field
    hmis_participations_field
    ce_participations_field
    services_field filter_args: { omit: [:project, :project_type], type_name: 'ServicesForProject' }
    hud_field :operating_start_date
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
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
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
    end
    field :unit_types, [Types::HmisSchema::UnitTypeCapacity], null: false
    field :has_units, Boolean, null: false

    field :data_collection_features, [Types::HmisSchema::DataCollectionFeature], null: false, description: 'Occurrence Point data collection features that are enabled for this Project (e.g. Current Living Situations, Events)'
    field :occurrence_point_forms, [Types::HmisSchema::OccurrencePointForm], null: false, method: :occurrence_point_form_instances, description: 'Forms for individual data elements that are collected at occurrence for this Project (e.g. Move-In Date)'
    # TODO: resolve related HMISParticipation records
    # TODO: resolve related CEParticipation records

    def data_collection_features
      object.data_collection_feature_instances.map do |role, instances|
        active_instances, legacy_instances = instances.partition(&:active)
        OpenStruct.new(
          id: [object.id, *instances.map(&:id)].join(':'),
          role: role.to_s,
          legacy: active_instances.none?,
          data_collected_about: active_instances.map { |i| i.data_collected_about || 'ALL_CLIENTS' }.uniq,
          legacy_data_collected_about: legacy_instances.map { |i| i.data_collected_about || 'ALL_CLIENTS' }.uniq,
        )
      end
    end

    def hud_id
      object.project_id
    end

    def enrollments(**args)
      return Hmis::Hud::Enrollment.none unless current_user.can_view_enrollment_details_for?(object)

      resolve_enrollments(object.enrollments_including_wip, **args)
    end

    def organization
      load_ar_association(object, :organization)
    end

    def inventories(**args)
      resolve_inventories(**args)
    end

    def services(**args)
      resolve_services(**args)
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

      object.units.map(&:unit_type).uniq.map do |unit_type|
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
      resolve_households(object.households_including_wip, **args)
    end

    def referral_requests(**args)
      scoped_referral_requests(object.external_referral_requests, **args)
    end

    def incoming_referral_postings(**args)
      scoped_referral_postings(object.external_referral_postings.active, **args)
    end

    def arel
      Hmis::ArelHelper.instance
    end

    def outgoing_referral_postings(**args)
      raise HmisErrors::ApiError, 'Access denied' unless current_permission?(entity: object, permission: :can_manage_outgoing_referrals)

      scope = HmisExternalApis::AcHmis::ReferralPosting.active
        .joins(referral: :enrollment)
        .where(arel.e_t[:ProjectID].eq(object.ProjectID))
      scoped_referral_postings(scope, **args)
    end
  end
end
