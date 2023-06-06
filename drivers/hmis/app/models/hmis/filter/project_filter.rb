###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::ProjectFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_funders)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_search_term)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :statuses) { scope.with_statuses(input.statuses) }
  end

  def with_funders(scope)
    with_filter(scope, :funders) { scope.with_funders(input.funders) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_types) { scope.with_project_type(input.project_types) }
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.matching_search_term(input.search_term) }
  end
end
