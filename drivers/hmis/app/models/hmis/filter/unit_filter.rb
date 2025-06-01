###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::UnitFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_unit_type)).
      yield_self(&method(:with_unit_group)).
      yield_self(&method(:with_status)). # deprecated
      yield_self(&method(:with_occupancy_status))
  end

  protected

  def with_status(scope) # deprecated
    with_filter(scope, :status) { scope.with_status(input.status) }
  end

  def with_occupancy_status(scope)
    with_filter(scope, :occupancy_status) do
      if input.occupancy_status.to_s == 'VACANT'
        scope.unoccupied_on
      elsif input.occupancy_status.to_s == 'OCCUPIED'
        scope.occupied_on
      else
        scope
      end
    end
  end

  def with_unit_type(scope)
    with_filter(scope, :unit_type) { scope.with_unit_type(input.unit_type) }
  end

  def with_unit_group(scope)
    with_filter(scope, :unit_group) { scope.where(hmis_unit_group_id: input.unit_group) }
  end
end
