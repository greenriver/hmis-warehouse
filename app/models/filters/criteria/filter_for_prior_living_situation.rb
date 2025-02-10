class Filters::Criteria::FilterForPriorLivingSituation < Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.prior_living_situation_ids.any?

  def apply(scope)
    scope.joins(:enrollment).merge(GrdaWarehouse::Hud::Enrollment.where(LivingSituation: input.prior_living_situation_ids))
  end
end
