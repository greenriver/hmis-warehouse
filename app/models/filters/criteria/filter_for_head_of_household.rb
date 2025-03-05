# frozen_string_literal: true

class Filters::Criteria::FilterForHeadOfHousehold < Filters::Criteria::Base
  def applies? = input.hoh_only

  def apply(scope)
    scope = super(scope)
    scope.where(arel.she_t[:head_of_household].eq(true))
  end
end
