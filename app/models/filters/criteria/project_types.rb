class Filters::Criteria::ProjectTypes < Filters::Criteria::Base
  LEVEL = :project
  attribute :project_types, :array

  def apply(scope)
    scope.in_project_type(project_types)
  end
end
