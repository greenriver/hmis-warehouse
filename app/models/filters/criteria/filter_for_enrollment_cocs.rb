###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForEnrollmentCocs < Filters::Criteria::Base
  def applies? = true

  def apply(scope)
    scope = super(scope)
    scope.left_outer_joins(:enrollment).
      # limit enrollment coc to the cocs chosen, and any random thing that's not a valid coc
      merge(
        GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: input.coc_codes).
        or(GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: nil)).
        or(GrdaWarehouse::Hud::Enrollment.where.not(EnrollmentCoC: HudUtility2026.cocs.keys)),
      )
  end
end
