module Filters::Components
  ProjectGroupFilter = Struct.new(:label, :project_group_ids, keyword_init: true) do
    def apply(scope)
      return scope if project_group_ids.blank?

      projects_groups = GrdaWarehouse::ProjectGroup.where(id: project_group_ids)
      project_ids = GrdaWarehouse::Hud::Project.
        joins(:project_groups).
        merge(projects_groups).
        distinct.
        pluck(:id)

      scope.in_project(project_ids)
    end
  end
end
