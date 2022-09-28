###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasAssessments
      extend ActiveSupport::Concern

      class_methods do
        def assessments_field(name = :assessments, description = nil, **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::Assessment], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::AssessmentSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_assessments_with_loader(association_name = :assessments, **args)
        load_ar_association(object, association_name, scope: apply_assessment_arguments(Hmis::Hud::Assessment, **args))
      end

      def resolve_assessments(scope = object.assessments, **args)
        apply_assessment_arguments(scope, **args)
      end

      private

      def apply_assessment_arguments(scope, user: current_user, sort_order: :assessment_date)
        assessments_scope = scope.viewable_by(user)
        assessments_scope.sort_by_option(sort_order) if sort_order.present?
      end
    end
  end
end
