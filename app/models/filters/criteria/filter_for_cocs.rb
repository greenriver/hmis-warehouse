###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForCocs < Filters::Criteria::Base
  def applies? = input.coc_codes.present?

  def apply(scope)
    scope = super(scope)
    return scope unless input.coc_codes.present?

    scope = filter_for_project_cocs(scope)
    filter_for_enrollment_cocs(scope)
  end

  protected

  # EXISTS rather than a join: projects can have several ProjectCoC rows in the same CoC, and
  # joining them repeats each enrollment once per row. Not a `where(id:)` on Project either,
  # because merging a later `where(id:)` (user access, project filters) would replace it.
  def filter_for_project_cocs(scope)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    pc_t = GrdaWarehouse::Hud::ProjectCoc.arel_table
    matching_project_cocs = GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: input.coc_codes).
      where(pc_t[:data_source_id].eq(p_t[:data_source_id]).and(pc_t[:ProjectID].eq(p_t[:ProjectID])))
    scope.joins(:project).where(matching_project_cocs.arel.exists)
  end

  def filter_for_enrollment_cocs(scope)
    scope.left_outer_joins(:enrollment).
      # limit enrollment coc to the cocs chosen, and any random thing that's not a valid coc
      merge(
        GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: input.coc_codes).
        or(GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: nil)).
        or(GrdaWarehouse::Hud::Enrollment.where.not(EnrollmentCoC: HudHelper.util.cocs.keys)),
      )
  end
end
