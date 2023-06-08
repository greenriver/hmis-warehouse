###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::AssessmentFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.
      yield_self(&method(:with_role)).
      yield_self(&method(:with_project_type)).
      yield_self(&method(:with_project)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_role(scope)
    with_filter(scope, :roles) { scope.with_role(input.roles) }
  end

  def with_project_type(scope)
    with_filter(scope, :project_types) { scope.with_project_type(input.project_types) }
  end

  def with_project(scope)
    with_filter(scope, :projects) { scope.with_project(input.projects) }
  end
end
