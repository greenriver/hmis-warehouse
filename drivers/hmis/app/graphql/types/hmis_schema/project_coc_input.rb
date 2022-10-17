module Types
  class HmisSchema::ProjectCocInput < BaseInputObject
    description 'HMIS Project CoC input'

    argument :project_id, ID, required: false
    argument :coc_code, String, required: false, validates: { length: { is: 6 } }
    argument :geocode, String, required: false, validates: { length: { is: 6 } }
    argument :address1, String, required: false
    argument :address2, String, required: false
    argument :city, String, required: false
    argument :state, String, required: false, validates: { length: { is: 2 } }
    argument :zip, String, required: false, validates: { length: { is: 5 } }
    argument :geography_type, HmisSchema::Enums::GeographyType, required: false

    def to_params
      result = to_h.except(:project_id)

      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
