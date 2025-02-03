class Filters::Criteria::ProjectId < Filters::Criteria::Base
  LEVEL = :project
  attribute :project_ids, :array

  def apply(scope)
    scope.in_project(project_ids)
  end
end
