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
    Rails.logger.info(">>> filtering #{input.inspect}")
    with_filter(scope, :project_type) do
      scope.eligible_for_project_type(input.project_type)
    end
  end

  def with_dynamic_filters(scope)
    with_filter(scope, :dynamic_filters) do
      scope = scope.join_latest_event_per_candidate_pool

      input.dynamic_filters.each do |filter|
        scope = scope.filter_by_attribute(key: filter.key, values: filter.values)
      end

      scope.distinct
    end
  end
end
