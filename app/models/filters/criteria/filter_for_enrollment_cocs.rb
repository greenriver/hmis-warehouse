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
        or(GrdaWarehouse::Hud::Enrollment.where.not(EnrollmentCoC: HudUtility2024.cocs.keys)),
      )
  end
end
