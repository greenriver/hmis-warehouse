###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeAssessments
      extend ActiveSupport::Concern

      class_methods do
        def ce_assessments_field(name = :ce_assessments, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::CeAssessment.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::AssessmentSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def ce_resolve_assessments(scope = object.assessments, **args)
        scoped_ce_assessments(scope, **args)
      end

      private

      def scoped_ce_assessments(scope, sort_order: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
