###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForEnrollmentCocs < Filters::Criteria::Base
  def applies? = true

  def apply(scope)
    scope = super(scope)
    scope.left_outer_joins(:enrollment).merge(enrollment_scope)
  end

  # Enrollments whose Enrollment CoC is one of the chosen CoCs, blank, or not a valid CoC code.
  # Public so a report that picks enrollments directly can apply the same rule.
  def enrollment_scope
    enrollments = GrdaWarehouse::Hud::Enrollment
    chosen_coc = enrollments.where(EnrollmentCoC: input.coc_codes)
    no_coc = enrollments.where(EnrollmentCoC: nil)
    invalid_coc = enrollments.where.not(EnrollmentCoC: HudHelper.util.cocs.keys)
    chosen_coc.or(no_coc).or(invalid_coc)
  end
end
