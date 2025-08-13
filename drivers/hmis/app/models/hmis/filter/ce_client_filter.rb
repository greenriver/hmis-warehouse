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
      yield_self(&method(:clean_scope))
  end

  protected

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.matching_search_term(input.search_term) }
  end

  def with_dynamic_filters(scope)
    with_filter(scope, :dynamic_filters) do
      # apply each filter
      input.dynamic_filters.each do |filter|
        Rails.logger.info(">>> applying filter #{filter.inspect}")
        scope = apply_dynamic_filter(scope, filter)
      end
      scope
    end
  end

  def apply_dynamic_filter(_scope, filter)
    raise "dynamic filter for #{filter.key} : #{filter.values.inspect}"
    # Events==> filter to most recent event per client per candidate pool
    # Search snapshot JSON for key<>value pairs

    # events = load_ar_association(object, :ce_match_candidate_events)
    #   events.group_by(&:candidate_pool_id).values.
    #     map { |arr| arr.max_by(&:created_at) }.
    #     sort_by(&:created_at).
    #     map(&:snapshot).reduce({}, :merge)
    # case filter.key
    # when 'veteran_status'
    #   scope.where(veteran_status: filter.values)
    # when 'age_group'
    #   scope.where(age_group: filter.values)
    # when 'housing_status'
    #   scope.where(housing_status: filter.values)
    # else
    #   scope # Ignore unknown filters
    # end
  end
end
