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
    include Types::HmisSchema::HasCustomDataElements

    def self.configuration
      Hmis::Hud::Project.hmis_configuration(version: '2022')
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
    hud_field :operating_start_date
    hud_field :operating_end_date
    hud_field :description, String, null: true
    hud_field :contact_information, String, null: true
    hud_field :housing_type, Types::HmisSchema::Enums::Hud::HousingType
    hud_field :tracking_method, Types::HmisSchema::Enums::Hud::TrackingMethod
    hud_field :target_population, HmisSchema::Enums::Hud::TargetPopulation
    hud_field :HOPWAMedAssistedLivingFac, HmisSchema::Enums::Hud::HOPWAMedAssistedLivingFac
    hud_field :continuum_project, HmisSchema::Enums::Hud::NoYesMissing, null: true
    hud_field :residential_affiliation, HmisSchema::Enums::Hud::NoYesMissing
    hud_field :HMISParticipatingProject, HmisSchema::Enums::Hud::NoYesMissing
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
    field :active, Boolean, null: false
    enrollments_field without_args: [:project_types]
    custom_data_elements_field
    referral_requests_field :referral_requests
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

    def hud_id
      object.project_id
    end

    def enrollments(**args)
      return Hmis::Hud::Enrollment.none unless current_user.can_view_enrollment_details_for?(object)

      # Apply the enrollment limit before we pass it in, to avoid doing an unnecessary join to the WIP table
      scope = if args[:enrollment_limit] == 'NON_WIP_ONLY'
        object.enrollments
      elsif args[:enrollment_limit] == 'WIP_ONLY'
        object.wip_enrollments
      else
        object.enrollments_including_wip
      end

      resolve_enrollments(scope, **args)
    end

    def organization
      load_ar_association(object, :organization)
    end

    def inventories(**args)
      resolve_inventories(**args)
    end

    def units(**args)
      resolve_units(**args)
    end

    def households(**args)
      resolve_households(**args)
    end

    def referral_requests(**args)
      scoped_referral_requests(object.external_referral_requests, **args)
    end
  end
end
