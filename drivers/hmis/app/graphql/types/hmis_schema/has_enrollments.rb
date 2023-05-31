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
        def enrollments_field(
          name = :enrollments,
          description = nil,
          type: Types::HmisSchema::Enrollment.page_type,
          filter_args: {},
          **override_options,
          &block
        )
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, HmisSchema::EnrollmentSortOption, required: false
            filters_argument HmisSchema::Enrollment, **filter_args

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

      def scoped_enrollments(scope, sort_order: :most_recent, filters: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
