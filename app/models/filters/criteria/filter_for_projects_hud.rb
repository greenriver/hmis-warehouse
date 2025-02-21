class Filters::Criteria::FilterForProjectsHud < Filters::Criteria::Base
  def applies? = input.project_ids.present?

  def apply(scope)
    scope.in_project(input.project_ids).merge(viewable_project_scope)
  end
end
