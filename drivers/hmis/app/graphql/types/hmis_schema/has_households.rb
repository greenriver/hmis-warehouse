###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasHouseholds
      extend ActiveSupport::Concern

      class_methods do
        def households_field(name = :households, description = nil, filter_args: {}, type: Types::HmisSchema::Household.page_type, **override_options, &block)
          default_field_options = {
            type: type,
            null: false,
            description: description,
            after_paginate: ->(nodes, ctx) {
              personal_ids = Hmis::Hud::Enrollment.where(household_id: nodes.map(&:HouseholdID)).pluck(:PersonalID)
              data_source_id = ctx[:current_user].hmis_data_source_id # rely on assumption that *enrollment* authorization guard prevents graphql from returning enrollments not in the current data source
              client_ids = Hmis::Hud::Client.where(data_source_id: data_source_id, PersonalID: personal_ids).pluck(:id)

              ctx[:current_user].policy_context.preload_client_dependencies(client_ids) unless client_ids.empty?
            },
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, HmisSchema::HouseholdSortOption, required: false
            filters_argument HmisSchema::Household, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_households(scope = object.households, **args)
        scoped_households(scope, **args)
      end

      private

      def scoped_households(scope, sort_order: :most_recent, filters: nil, dangerous_skip_permission_check: false)
        scope = scope.viewable_by(current_user) unless dangerous_skip_permission_check
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
