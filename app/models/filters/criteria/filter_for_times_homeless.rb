class Filters::Criteria::FilterForTimesHomeless < Filters::Criteria::Base
  def applies? = input.times_homeless_in_last_three_years.present?

  def apply(scope)
    scope.joins(:enrollment).where(arel.e_t[:TimesHomelessPastThreeYears].in(input.times_homeless_in_last_three_years))
  end
end
