###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::ClientFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_project)).
      yield_self(&method(:with_organization))
  end

  protected

  def with_project(scope)
    with_filter(scope, :project) { scope.with_open_enrollment_in_project(input.project) }
  end

  def with_organization(scope)
    with_filter(scope, :organization) { scope.with_open_enrollment_in_organization(input.organization) }
  end
end
