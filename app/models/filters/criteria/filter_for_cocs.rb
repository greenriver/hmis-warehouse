class Filters::Criteria::FilterForCocs < Filters::Criteria::Base
  LEVEL = :project

  def applies? = coc_codes.present?

  def apply(scope)
    if config.multi_coc_code_filter
      filter_for_cocs(scope)
    else
      filter_for_coc(scope)
    end
  end

  protected

  def filter_for_cocs(scope)
    return scope unless input.coc_codes.present?

    scope = filter_for_project_cocs(scope)
    filter_for_enrollment_cocs(scope)
  end

  def filter_for_project_cocs(scope)
    scope.joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: input.coc_codes))
  end

  def filter_for_enrollment_cocs(scope)
    scope.left_outer_joins(:enrollment).
      # limit enrollment coc to the cocs chosen, and any random thing that's not a valid coc
      merge(
        GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: input.coc_codes).
        or(GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: nil)).
        or(GrdaWarehouse::Hud::Enrollment.where.not(EnrollmentCoC: HudUtility2024.cocs.keys)),
      )
  end

  def filter_for_coc(scope)
    return scope unless input.coc_code.present?

    scope.joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: input.coc_code))
  end
end
