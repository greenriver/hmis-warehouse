module Types
  class HmisSchema::ProjectInput < BaseInputObject
    description 'HMIS Project input'

    argument :organization_id, ID, required: false
    argument :project_name, String, required: false
    date_string_argument :operating_start_date, 'Date with format yyyy-mm-dd', required: false
    date_string_argument :operating_end_date, 'Date with format yyyy-mm-dd', required: false
    argument :description, String, required: false
    argument :contact_information, String, required: false
    argument :project_type, Types::HmisSchema::Enums::ProjectType, required: false
    argument :housing_type, Types::HmisSchema::Enums::HousingType, required: false
    argument :tracking_method, Types::HmisSchema::Enums::TrackingMethod, required: false
    argument :target_population, HmisSchema::Enums::TargetPopulation, required: false
    argument :HOPWAMedAssistedLivingFac, HmisSchema::Enums::HOPWAMedAssistedLivingFac, required: false
    yes_no_missing_argument :continuum_project, required: false
    yes_no_missing_argument :residential_affiliation, required: false
    yes_no_missing_argument :HMISParticipatingProject, required: false

    def to_params
      result = to_h.except(:organization_id)

      result[:organization_id] = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: organization_id)&.organization_id if organization_id.present?

      result
    end
  end
end
