###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def self.configuration
      Hmis::Hud::Project.hmis_configuration(version: '2022')
    end

    hud_field :id, ID, null: false
    hud_field :project_name
    hud_field :project_type, Types::HmisSchema::Enums::ProjectType
    hud_field :organization, Types::HmisSchema::Organization, null: false
    inventories_field
    project_cocs_field
    funders_field
    hud_field :operating_start_date
    hud_field :operating_end_date
    hud_field :description, String, null: true
    hud_field :contact_information, String, null: true
    hud_field :housing_type, Types::HmisSchema::Enums::Hud::HousingType
    hud_field :tracking_method, Types::HmisSchema::Enums::Hud::TrackingMethod
    hud_field :target_population, HmisSchema::Enums::Hud::TargetPopulation
    hud_field :HOPWAMedAssistedLivingFac, HmisSchema::Enums::Hud::HOPWAMedAssistedLivingFac
    yes_no_missing_field :continuum_project
    yes_no_missing_field :residential_affiliation
    yes_no_missing_field :HMISParticipatingProject
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :active, Boolean, null: false
    enrollments_field without_args: [:project_types]

    access_field do
      can :delete_project
      can :edit_project_details
    end

    def enrollments(**args)
      resolve_enrollments(**args)
    end

    def organization
      load_ar_association(object, :organization)
    end

    def inventories(**args)
      resolve_inventories(**args)
    end
  end
end
