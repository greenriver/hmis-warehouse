module Mutations
  class CreateProject < BaseMutation
    argument :input, Types::HmisSchema::ProjectInput, required: true

    field :project, Types::HmisSchema::Project, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      user = hmis_user

      project = Hmis::Hud::Project.new(
        **input.to_params,
        project_id: Hmis::Hud::Project.generate_project_id,
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        date_updated: DateTime.current,
        date_created: DateTime.current,
      )

      errors = []

      if project.valid?
        project.save!
      else
        errors = project.errors
        project = nil
      end

      {
        project: project,
        errors: errors,
      }
    end
  end
end
