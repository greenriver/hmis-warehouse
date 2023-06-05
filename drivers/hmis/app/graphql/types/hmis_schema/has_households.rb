###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, HmisSchema::HouseholdSortOption, required: false
            argument :enrollment_limit, HmisSchema::EnrollmentLimit, required: false
            argument :open_on_date, GraphQL::Types::ISO8601Date, required: false
            argument :search_term, String, required: false
            filters_argument HmisSchema::Household, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_households_with_loader(association_name = :households, **args)
        load_ar_association(object, association_name, scope: scoped_households(Hmis::Hud::Enrollment, **args))
      end

      def resolve_households(scope = object.households, **args)
        scoped_households(scope, **args)
      end

      private

      def scoped_households(scope, sort_order: :most_recent, enrollment_limit: nil, open_on_date: nil, search_term: nil, filters: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.not_in_progress if enrollment_limit == 'NON_WIP_ONLY'
        scope = scope.in_progress if enrollment_limit == 'WIP_ONLY'
        scope = scope.open_on_date(open_on_date) if open_on_date.present?
        scope = scope.client_matches_search_term(search_term) if search_term.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
