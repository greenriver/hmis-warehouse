###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  module Admin
    module HasFormRules
      extend ActiveSupport::Concern

      class_methods do
        def form_rules_field(
          name = :form_rules,
          description = nil,
          filter_args: {},
          **override_options,
          &block
        )
          default_field_options = { type: Types::Admin::FormRule.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::Admin::FormRuleSortOption, required: false
            filters_argument Types::Admin::FormRule, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_form_rules(scope, sort_order: nil, filters: nil)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
