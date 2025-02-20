class Filters::Criteria::FilterForHeadOfHousehold < Filters::Criteria::Base
  def applies? = input.hoh_only

  def apply(scope)
    scope.where(arel.she_t[:head_of_household].eq(true))
  end
end
