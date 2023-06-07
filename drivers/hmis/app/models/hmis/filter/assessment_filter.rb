###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::AssessmentFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.
      yield_self(&method(:with_roles)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_projects)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_roles(scope)
    with_filter(scope, :roles) { scope.with_role(input.roles) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_types) { scope.with_project_types(input.project_types) }
  end

  def with_projects(scope)
    with_filter(scope, :projects) { scope.with_projects(input.projects) }
  end
end
