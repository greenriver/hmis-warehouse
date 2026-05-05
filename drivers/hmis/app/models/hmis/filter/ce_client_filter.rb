###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeClientFilter < Hmis::Filter::BaseFilter
  include ::Hmis::Concerns::HmisArelHelper

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_search_term)).
      yield_self(&method(:with_dynamic_filters)).
      yield_self(&method(:with_project_type)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_search_term(scope)
    with_filter(scope, :search_term) do
      scope.matching_search_term(input.search_term)
    end
  end

  def with_project_type(scope)
    with_filter(scope, :project_type) do
      scope.eligible_for_project_type(input.project_type)
    end
  end

  def with_dynamic_filters(scope)
    with_filter(scope, :dynamic_filters) do
      # Safety: skip if there is a huge number of filters
      if input.dynamic_filters.size > 50
        msg = "CE client dynamic filters limit is 50, received #{input.dynamic_filters.size}. Skipping dynamic filters."
        raise ArgumentError, msg if Rails.env.development? || Rails.env.test?

        Sentry.capture_message(msg)
        return scope
      end

      input.dynamic_filters.each do |filter|
        # Validate key. Filtering not supported for non-CDE keys. Raise in dev, otherwise skip and report to Sentry.
        field_type, custom_assessment_field = Hmis::Ce::Match::Expression::FieldMap.field_type_for(filter.key)
        if field_type != Hmis::Ce::Match::Expression::FieldMap::CDE
          msg = "CE client dynamic filters only support `cde.*` expression keys. Skipping filter on key: #{filter.key.inspect}"
          raise ArgumentError, msg if Rails.env.development? || Rails.env.test?

          Sentry.capture_message(msg)
          next
        end

        scope = scope.matching_dynamic_cde_filter(custom_assessment_field, filter.values)
      end

      scope.distinct
    end
  end
end
