###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeReferrals
      extend ActiveSupport::Concern

      class_methods do
        def ce_referrals_field(name = :ce_referrals, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = {
            type: Types::HmisSchema::CeReferral.page_type,
            null: false,
            description: description,
            after_paginate: ->(nodes, ctx) {
              ctx[:current_user].policy_context.preload_referral_dependencies(nodes.map(&:id))
            },
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument HmisSchema::CeReferral, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      included do
        def resolve_ce_referrals(scope = object.ce_referrals, **args)
          scoped_ce_referrals(scope, **args)
        end
      end

      private

      def scoped_ce_referrals(scope, sort_order: :status, user: current_user, filters: nil, dangerous_skip_permission_check: false)
        raise unless Hmis::Ce.configuration.enabled?

        scope = scope.viewable_by(user) unless dangerous_skip_permission_check
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?

        scope
      end
    end
  end
end
