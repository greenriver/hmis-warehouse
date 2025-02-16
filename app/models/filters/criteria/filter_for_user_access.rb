class Filters::Criteria::FilterForUserAccess < Filters::Criteria::Base
  def applies? = true

  def apply(scope)
    scope.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(input.user, permission: :can_view_assigned_reports))
  end
end
