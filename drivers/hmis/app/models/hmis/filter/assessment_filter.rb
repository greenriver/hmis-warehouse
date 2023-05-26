###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::AssessmentFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.
      yield_self(&method(:with_roles)).
      yield_self(&method(:with_projects)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_roles(scope)
    return scope unless input.roles&.present?

    with_filter(scope, input, :roles) { scope.with_role(input.roles) }
  end

  def with_projects(scope)
    return scope unless input.projects&.present? # any?

    with_filter(scope, input, :roles) { scope.in_projects(input.projects) }
  end
end
