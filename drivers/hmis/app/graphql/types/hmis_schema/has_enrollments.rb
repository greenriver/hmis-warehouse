###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasEnrollments
      extend ActiveSupport::Concern

      class_methods do
        def enrollments_field(name = :enrollments, description = nil, type: Types::HmisSchema::Enrollment.page_type, **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, HmisSchema::EnrollmentSortOption, required: false
            argument :include_in_progress, GraphQL::Types::Boolean, required: false
            argument :project_types, [Types::HmisSchema::Enums::ProjectType], required: false
            argument :client_search_term, String, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_enrollments_with_loader(association_name = :enrollments, **args)
        load_ar_association(object, association_name, scope: scoped_enrollments(Hmis::Hud::Enrollment, **args))
      end

      def resolve_enrollments(scope = object.enrollments, **args)
        scoped_enrollments(scope, **args)
      end

      private

      def scoped_enrollments(scope, sort_order: :most_recent, include_in_progress: false, project_types: nil, client_search_term: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.where.not(project_id: nil) unless include_in_progress
        scope = scope.with_project_type(project_types) if project_types.present?
        scope = scope.joins(:client).merge(Hmis::Hud::Client.matching_search_term(client_search_term)) if client_search_term.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
