###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasAssessments
      extend ActiveSupport::Concern

      class_methods do
        def assessments_field(name = :assessments, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: HmisSchema::Assessment.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::AssessmentSortOption, required: false
            argument :in_progress, GraphQL::Types::Boolean, required: false
            filters_argument HmisSchema::Assessment, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_assessments_with_loader(association_name = :custom_assessments, **args)
        load_ar_association(object, association_name, scope: scoped_assessments(Hmis::Hud::CustomAssessment, **args))
      end

      def resolve_assessments(scope = object.custom_assessments, **args)
        scoped_assessments(scope, **args)
      end

      def resolve_assessments_including_wip(scope = object.custom_assessments_including_wip, **args)
        scoped_assessments(scope, **args)
      end

      private

      def scoped_assessments(scope, sort_order: nil, in_progress: nil, filters: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope = scope.in_progress if in_progress == true
        scope = scope.not_in_progress if in_progress == false
        scope
      end
    end
  end
end
