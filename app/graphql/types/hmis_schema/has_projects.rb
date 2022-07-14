module Types
  module HmisSchema
    module HasProjects
      extend ActiveSupport::Concern

      class_methods do
        def projects_field(name = :projects, description = nil, without_args: [], **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::Project], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :project_types, [Types::HmisSchema::ProjectType], required: false unless without_args.include? :project_types
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_projects(scope = object.projects, user: current_user, project_types: nil)
        projects_scope = scope.viewable_by(user)
        projects_scope = projects_scope.with_project_type(project_types) if project_types.present?
        projects_scope
      end
    end
  end
end
