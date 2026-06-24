###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeMatchRuleFilter < Hmis::Filter::BaseFilter
  GLOBAL_OWNER_TYPE = 'GrdaWarehouse::DataSource'

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_global))
  end

  protected

  def with_global(scope)
    return scope unless input.respond_to?(:global) && input.global == true

    scope.where(owner_type: GLOBAL_OWNER_TYPE)
  end
end
