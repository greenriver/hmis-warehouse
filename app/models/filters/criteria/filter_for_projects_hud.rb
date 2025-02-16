class Filters::Criteria::FilterForProjectsHud < Filters::Criteria::Base
  def applies? = input.project_ids.present?

  def apply(scope)
    scope.in_project(@filter.project_ids).
      merge(GrdaWarehouse::Hud::Project.viewable_by(input.user, permission: :can_view_assigned_reports))
  end
end
