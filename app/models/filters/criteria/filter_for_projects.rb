class Filters::Criteria::FilterForProjects < Filters::Criteria::Base
  def applies?
    input.project_ids.present? || input.project_group_ids.present?
  end

  def apply(scope)
    project_ids = visible_project_ids
    return scope if project_ids.blank?

    # seems to be order dependent (merge before in_project)
    scope.merge(viewable_project_scope).in_project(project_ids)
  end

  protected

  def visible_project_ids
    project_ids = []
    project_ids += input.project_ids || [] if user.report_filter_visible?(:project_ids)

    # note, this is from the original logic: filter by groups even if user cannot filter by project_id
    project_groups = GrdaWarehouse::ProjectGroup.where(id: input.project_group_ids)
    project_groups.each do |group|
      project_ids += group.projects.pluck(:id)
    end
    project_ids.uniq
  end
end
