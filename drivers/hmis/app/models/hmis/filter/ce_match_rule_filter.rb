###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeMatchRuleFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_owner_type)).
      yield_self(&method(:with_owner_id))
  end

  protected

  def with_owner_type(scope)
    with_filter(scope, :owner_type) { scope.where(owner_type: input.owner_type) }
  end

  def with_owner_id(scope)
    with_filter(scope, :owner_id) { scope.where(owner_id: input.owner_id) }
  end
end
