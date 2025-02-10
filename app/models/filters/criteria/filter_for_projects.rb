class Filters::Criteria::FilterForProjects < Filters::Criteria::Base
  LEVEL = :project

  def applies?
    return false unless input.project_ids.present? || input.project_group_ids.present?

    user.report_filter_visible?(:project_ids)
  end

  def apply(scope)
    project_ids = input.project_ids.dup
    project_groups = GrdaWarehouse::ProjectGroup.where(id: input.project_group_ids)
    project_groups.each do |group|
      project_ids += group.projects.pluck(:id)
    end

    return scope if project_ids.blank?

    scope.in_project(project_ids.uniq).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports))
  end
end
