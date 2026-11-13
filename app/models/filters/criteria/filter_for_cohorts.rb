###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForCohorts < Filters::Criteria::Base
  def applies? = input.cohort_ids.present?

  def apply(scope)
    scope = super(scope)
    scope.on_cohort(cohort_id: input.cohort_ids)
  end
end
