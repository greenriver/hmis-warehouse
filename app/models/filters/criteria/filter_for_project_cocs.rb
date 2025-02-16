class Filters::Criteria::FilterForProjectCocs < Filters::Criteria::Base
  def applies? = true

  def apply(scope)
    scope.joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: input.coc_codes))
  end
end
