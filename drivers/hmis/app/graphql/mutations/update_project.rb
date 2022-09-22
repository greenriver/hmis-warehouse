module Mutations
  class UpdateProject < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectInput, required: true

    field :project, Types::HmisSchema::Project, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      errors = []
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)

      if project.present?
        project.update(**input.to_params)
        errors += project.errors.errors unless project.valid?
      else
        errors << InputValidationError.new("No project found with ID '#{id}'", attribute: 'id') unless project.present?
      end

      {
        project: project,
        errors: errors,
      }
    end
  end
end
