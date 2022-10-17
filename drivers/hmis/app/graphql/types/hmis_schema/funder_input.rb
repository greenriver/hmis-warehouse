module Types
  class HmisSchema::FunderInput < BaseInputObject
    description 'HMIS Funder input'

    argument :project_id, ID, required: false
    argument :funder, HmisSchema::Enums::FundingSource, required: false
    argument :other_funder, String, required: false
    argument :grant_id, String, required: false
    argument :start_date, GraphQL::Types::ISO8601Date, required: false
    argument :end_date, GraphQL::Types::ISO8601Date, required: false

    def to_params
      result = to_h.except(:project_id)

      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
