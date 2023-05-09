###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
          default_field_options = { type: Types::HmisSchema::Project.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :project_types, [Types::HmisSchema::Enums::ProjectType], required: false unless without_args.include? :project_types
            argument :search_term, String, required: false unless without_args.include? :search_term
            argument :sort_order, Types::HmisSchema::ProjectSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      included do
        def resolve_projects_with_loader(association_name = :projects, **args)
          load_ar_association(object, association_name, scope: scoped_projects(Hmis::Hud::Project, **args))
        end

        def resolve_projects(scope = object.projects, **args)
          scoped_projects(scope, **args)
        end
      end

      private

      def scoped_projects(scope, user: current_user, project_types: nil, search_term: nil, sort_order: nil)
        scope = scope.viewable_by(user)
        scope = scope.with_project_type(project_types) if project_types.present?
        scope = scope.matching_search_term(search_term) if search_term.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
