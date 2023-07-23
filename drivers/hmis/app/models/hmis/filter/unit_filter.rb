###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::UnitFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.
      yield_self(&method(:with_unit_type)).
      yield_self(&method(:with_status))
  end

  protected

  def with_status(scope)
    with_filter(scope, :status) { scope.with_status(input.status) }
  end

  def with_unit_type(scope)
    with_filter(scope, :unit_type) { scope.with_unit_type(input.unit_type) }
  end
end
