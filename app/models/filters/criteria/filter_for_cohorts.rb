# frozen_string_literal: true

class Filters::Criteria::FilterForCohorts < Filters::Criteria::Base
  def applies? = input.cohort_ids.present?

  def apply(scope)
    scope = super(scope)
    scope.on_cohort(cohort_id: input.cohort_ids)
  end
end
