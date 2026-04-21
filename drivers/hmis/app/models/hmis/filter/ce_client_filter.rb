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
      return scope if input.dynamic_filters.size > 50

      input.dynamic_filters.each do |filter|
        # Skip if no values to match
        string_values = Array.wrap(filter.values).map(&:to_s).reject(&:blank?).uniq
        next if string_values.empty?

        # Validate key. Filtering not supported for non-CDE keys. Raise in dev, otherwise skip and report to Sentry.
        field_type, = Hmis::Ce::Match::Expression::FieldMap.field_type_for(filter.key)
        if field_type != Hmis::Ce::Match::Expression::FieldMap::CDE
          msg = "CE client dynamic filters only support `cde.*` expression keys. Skipping filter on key: #{filter.key.inspect}"
          raise ArgumentError, msg if Rails.env.development?

          Sentry.capture_message(msg)
          next
        end

        _, resolved = Hmis::Ce::Match::Expression::FieldMap.field_type_for(filter.key)
        sql, binds = Hmis::Ce::Match::Expression::CdeFieldMap.sql_cde_value_exists_for_ce_client_proxy(resolved, string_values)
        scope = scope.where([sql, *binds])
      end

      scope.distinct
    end
  end
end
