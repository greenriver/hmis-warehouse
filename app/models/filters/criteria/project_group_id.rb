class Filters::Criteria::ProjectGroupId < Filters::Criteria::Base
  LEVEL = :client

  attribute :project_group_ids, :array

  def apply(scope)
    projects_groups = GrdaWarehouse::ProjectGroup.where(id: project_group_ids)
    project_ids = GrdaWarehouse::Hud::Project.
      joins(:project_groups).
      merge(projects_groups).
      distinct.
      pluck(:id)

    scope.in_project(project_ids)
  end
end
