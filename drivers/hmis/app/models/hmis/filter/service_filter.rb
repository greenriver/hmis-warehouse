###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::ServiceFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.
      yield_self(&method(:with_service_category)).
      yield_self(&method(:with_service_type)).
      yield_self(&method(:with_project_type)).
      yield_self(&method(:with_project)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_service_category(scope)
    with_filter(scope, :service_category) { scope.in_service_category(input.service_category) }
  end

  def with_service_type(scope)
    with_filter(scope, :service_type) { scope.with_service_type(input.service_type) }
  end

  def with_project_type(scope)
    with_filter(scope, :project_type) { scope.with_project_type(input.project_type) }
  end

  def with_project(scope)
    with_filter(scope, :project) { scope.with_project(input.project) }
  end
end
