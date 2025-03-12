# frozen_string_literal: true

class Filters::Criteria::FilterForProjects < Filters::Criteria::Base
  def applies?
    input.project_ids.present? || input.project_group_ids.present?
  end

  def apply(scope)
    scope = super(scope)
    project_ids = visible_project_ids
    return scope if project_ids.blank?

    # seems to be order dependent (merge before in_project)
    scope.merge(viewable_project_scope).in_project(project_ids)
  end

  protected

  def visible_project_ids
    project_ids = []
    project_ids += input.project_ids || [] if user.report_filter_visible?(:project_ids)

    # Note: since filtering by project groups amounts to filtering by sets of project ids, and they need to be OR'd with projects so that they aren't limiting to overlaps with chosen projects, we extract the project_ids from the chosen project groups and add them to those from the projects input.
    project_groups = GrdaWarehouse::ProjectGroup.where(id: input.project_group_ids)
    project_groups.each do |group|
      project_ids += group.projects.pluck(:id)
    end
    project_ids.uniq
  end
end
