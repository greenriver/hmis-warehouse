###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeOpportunities
      extend ActiveSupport::Concern

      include ::Hmis::Concerns::HmisArelHelper

      class_methods do
        def ce_opportunities_field(name = :ce_opportunities, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: Types::HmisSchema::CeOpportunity.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::CeOpportunitySortOption, required: false
            filters_argument HmisSchema::CeOpportunity, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      included do
        def resolve_ce_opportunities(scope = object.ce_opportunities, **args)
          scoped_ce_opportunities(scope, **args)
        end
      end

      private

      def scoped_ce_opportunities(scope, user: current_user, sort_order: nil, filters: nil, dangerous_skip_permission_check: false)
        raise unless Hmis::Ce.configuration.enabled?

        scope = scope.viewable_by(user) unless dangerous_skip_permission_check
        scope = scope.apply_filters(filters) if filters.present?

        sort_order ||= :date_available_earliest_first
        scope.sort_by_option(sort_order)
      end
    end
  end
end
