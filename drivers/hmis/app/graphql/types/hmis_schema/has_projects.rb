###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasProjects
      include ArelHelper
      extend ActiveSupport::Concern

      class_methods do
        def projects_field(name = :projects, description = nil, without_args: [], **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::Project], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :project_types, [Types::HmisSchema::ProjectType], required: false unless without_args.include? :project_types
            argument :sort_by, Types::HmisSchema::ProjectSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_projects(scope = object.projects, user: current_user, project_types: nil, sort_by: :organization_and_name)
        projects_scope = scope.viewable_by(user)
        projects_scope = projects_scope.with_project_type(project_types) if project_types.present?

        # FIXME: define sort function in the enum or somewhere else?
        projects_scope = projects_scope.joins(:organization).order(o_t[:OrganizationName], p_t[:ProjectName]) if sort_by.present?

        projects_scope
      end
    end
  end
end
