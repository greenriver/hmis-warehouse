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
        def projects_field(name = :projects, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: Types::HmisSchema::Project.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::ProjectSortOption, required: false
            filters_argument HmisSchema::Project, **filter_args
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

      def scoped_projects(scope, user: current_user, sort_order: nil, filters: nil)
        scope = scope.viewable_by(user)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
