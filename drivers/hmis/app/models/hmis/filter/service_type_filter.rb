###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::ServiceTypeFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope = with_search_term(scope)
    scope = with_include_hud_services(scope)
    scope = with_service_categories(scope)
    scope = with_supports_bulk_assignment(scope)
    scope
  end

  protected

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.matching_search_term(input.search_term) }
  end

  def with_include_hud_services(scope)
    if input.include_hud_services
      scope
    else
      scope.custom
    end
  end

  def with_service_categories(scope)
    with_filter(scope, :service_category) { scope.where(custom_service_category_id: input.service_category) }
  end

  # Yes/No rather than a boolean, so that service types that do not support bulk assignment are
  # filterable on their own.
  def with_supports_bulk_assignment(scope)
    with_filter(scope, :supports_bulk_assignment) do
      scope.where(supports_bulk_assignment: input.supports_bulk_assignment.to_s == 'YES')
    end
  end
end
