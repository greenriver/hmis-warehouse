###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
            argument :sort_order, Types::HmisSchema::ProjectSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_projects_with_loader(association_name = :projects, user: current_user, project_types: nil, sort_order: nil)
        projects_scope = Hmis::Hud::Project.viewable_by(user)
        projects_scope = projects_scope.with_project_type(project_types) if project_types.present?
        projects_scope = projects_scope.sort_by_option(sort_order) if sort_order.present?
        load_ar_association(object, association_name, scope: projects_scope)
      end

      def resolve_projects(scope = object.projects, user: current_user, project_types: nil, sort_order: nil)
        projects_scope = scope.viewable_by(user)
        projects_scope = projects_scope.with_project_type(project_types) if project_types.present?
        projects_scope = projects_scope.sort_by_option(sort_order) if sort_order.present?

        projects_scope
      end
    end
  end
end
