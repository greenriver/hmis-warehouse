###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForPriorLivingSituation < Filters::Criteria::Base
  def applies? = input.prior_living_situation_ids.any?

  def apply(scope)
    scope = super(scope)
    scope.joins(:enrollment).merge(GrdaWarehouse::Hud::Enrollment.where(LivingSituation: input.prior_living_situation_ids))
  end
end
