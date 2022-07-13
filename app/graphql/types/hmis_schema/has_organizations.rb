module Types
  module HmisSchema
    module HasOrganizations
      extend ActiveSupport::Concern

      class_methods do
        def organizations_field(name = :organizations, description = nil, without_args: [], **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::Organization], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :exclude_confidential, GraphQL::Types::Boolean, required: false unless without_args.include? :exclude_confidential
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_organizations(scope = object.organizations, user: current_user, exclude_confidential: false)
        organizations_scope = scope.viewable_by(user)
        organizations_scope = organizations_scope.non_confidential if exclude_confidential && !user.can_view_confidential_project_names?
        organizations_scope
      end
    end
  end
end
