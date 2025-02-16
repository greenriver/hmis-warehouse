class Filters::Criteria::FilterForProjectsHud < Filters::Criteria::Base

  def applies? = input.project_ids.present?

  def apply(scope)
    scope.joins(config.join_clients_method).
      where(arel.c_t[:VeteranStatus].in(input.veteran_statuses))
    scope.in_project(input.project_ids).merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports))
  end
end
