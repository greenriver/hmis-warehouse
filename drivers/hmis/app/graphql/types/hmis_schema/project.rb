###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Project < Types::BaseObject
    description 'HUD Project'
    field :id, ID, null: false
    field :project_name, String, method: :ProjectName, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, method: :ProjectType, null: true
    field :organization, Types::HmisSchema::Organization, null: false
    field :operating_start_date, GraphQL::Types::ISO8601Date, null: false
    field :operating_end_date, GraphQL::Types::ISO8601Date, null: true
    field :description, String, null: true
    field :contact_information, String, null: true
    field :housing_type, Types::HmisSchema::Enums::HousingType, null: true
    field :tracking_method, Types::HmisSchema::Enums::TrackingMethod, null: true
    field :target_population, HmisSchema::Enums::TargetPopulation, null: true
    field :HOPWAMedAssistedLivingFac, HmisSchema::Enums::HOPWAMedAssistedLivingFac, null: true
    field :continuum_project, Int, null: true
    field :residential_affiliation, Int, null: true
    field :HMISParticipatingProject, Int, null: true

    def organization
      load_ar_association(object, :organization)
    end
  end
end
