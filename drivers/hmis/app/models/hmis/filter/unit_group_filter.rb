# frozen_string_literal: true

class Hmis::Filter::UnitGroupFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_search_term)).
      yield_self(&method(:with_ce_waitlists_enabled)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.matching_search_term(input.search_term) }
  end

  def with_ce_waitlists_enabled(scope)
    with_filter(scope, :ce_waitlists_enabled) { input.ce_waitlists_enabled == true ? scope.with_ce_waitlists_enabled : scope }
  end
end
