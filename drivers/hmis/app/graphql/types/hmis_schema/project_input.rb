module Types
  class HmisSchema::ProjectInput < BaseInputObject
    def self.source_type
      HmisSchema::Project
    end

    hud_argument :organization_id, ID
    hud_argument :project_name
    date_string_argument :operating_start_date, 'Date with format yyyy-mm-dd', required: false
    date_string_argument :operating_end_date, 'Date with format yyyy-mm-dd', required: false
    hud_argument :description, String
    hud_argument :contact_information, String
    hud_argument :project_type, Types::HmisSchema::Enums::ProjectType
    hud_argument :housing_type, Types::HmisSchema::Enums::Hud::HousingType
    hud_argument :tracking_method, Types::HmisSchema::Enums::Hud::TrackingMethod
    hud_argument :target_population, HmisSchema::Enums::Hud::TargetPopulation
    hud_argument :HOPWAMedAssistedLivingFac, HmisSchema::Enums::Hud::HOPWAMedAssistedLivingFac
    yes_no_missing_argument :continuum_project, required: false
    yes_no_missing_argument :residential_affiliation, required: false
    yes_no_missing_argument :HMISParticipatingProject, required: false

    def to_params
      result = to_h.except(:organization_id)

      result[:organization_id] = Hmis::Hud::Organization.editable_by(current_user).find_by(id: organization_id)&.organization_id if organization_id.present?

      result
    end
  end
end
