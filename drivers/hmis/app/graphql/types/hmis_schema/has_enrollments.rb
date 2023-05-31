###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasEnrollments
      extend ActiveSupport::Concern

      class_methods do
        def enrollments_field(name = :enrollments, description = nil, type: Types::HmisSchema::Enrollment.page_type, without_args: [], filter_type_name: nil, filter_omit: [], filter_args: {}, **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, HmisSchema::EnrollmentSortOption, required: false
            argument :enrollment_limit, HmisSchema::EnrollmentLimit, required: false
            argument :open_on_date, GraphQL::Types::ISO8601Date, required: false
            argument :project_types, [Types::HmisSchema::Enums::ProjectType], required: false unless without_args.include? :project_types
            argument :search_term, String, required: false unless without_args.include? :search_term

            filters_argument HmisSchema::Enrollment, type_name: filter_type_name, omit: filter_omit, **filter_args

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

      def scoped_enrollments(scope, sort_order: :most_recent, enrollment_limit: nil, open_on_date: nil, project_types: nil, search_term: nil, filters: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.not_in_progress if enrollment_limit == 'NON_WIP_ONLY'
        scope = scope.in_progress if enrollment_limit == 'WIP_ONLY'
        scope = scope.open_on_date(open_on_date) if open_on_date.present?
        scope = scope.with_project_type(project_types) if project_types.present?
        scope = scope.matching_search_term(search_term) if search_term.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
