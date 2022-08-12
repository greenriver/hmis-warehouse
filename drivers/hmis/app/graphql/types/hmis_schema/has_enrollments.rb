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
        def enrollments_field(name = :enrollments, description = nil, type: [Types::HmisSchema::Enrollment], **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_enrollments_with_loader(association_name = :enrollments, **args)
        load_ar_association(object, association_name, scope: apply_enrollment_arguments(Hmis::Hud::Enrollment.all, **args))
      end

      def resolve_enrollments(scope = object.enrollments, **args)
        apply_enrollment_arguments(scope, **args)
      end

      private

      def apply_enrollment_arguments(scope, _user: current_user)
        scope
      end
    end
  end
end
