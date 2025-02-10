class Filters::Criteria::FilterForUserAccess < Filters::Criteria::Base
  LEVEL = :project

  def applies?(_input) = true

  def apply(scope)
    scope.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(input.user, permission: :can_view_assigned_reports))
  end
end
