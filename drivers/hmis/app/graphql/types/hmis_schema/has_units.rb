###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasUnits
      extend ActiveSupport::Concern

      class_methods do
        def units_field(name = :units, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = {
            type: HmisSchema::Unit.page_type,
            null: false,
            description: description,
            after_paginate: ->(nodes, ctx) {
              return unless Hmis::Ce.configuration.enabled?

              # this isn't ideal but avoids n+1 when referencing active referral through opportunity
              referral_ids = Hmis::Ce::Opportunity.active_referral_ids_for_units(nodes)
              ctx[:current_user].policy_context.preload_referral_dependencies(referral_ids)
            },
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument HmisSchema::Unit, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_units(scope = object.units, filters: nil)
        scope = scope.apply_filters(filters) if filters.present?
        scope.order(created_at: :desc)
      end
    end
  end
end
