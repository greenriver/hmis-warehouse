###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasIncomeBenefits
      extend ActiveSupport::Concern

      class_methods do
        def income_benefits_field(name = :events, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::IncomeBenefit.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            # argument :sort_order, Types::HmisSchema::IncomeBenefitsSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_income_benefits(scope = object.income_benefits, **args)
        scoped_income_benefits(scope, **args)
      end

      private

      def scoped_income_benefits(scope)
        scope.viewable_by(current_user)
      end
    end
  end
end
