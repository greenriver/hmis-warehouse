class Filters::Criteria::FilterForCohorts < Filters::Criteria::Base
  def applies? = input.cohort_ids.present?

  def apply(scope)
    scope.on_cohort(cohort_id: input.cohort_ids)
  end
end
