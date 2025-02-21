class Filters::Criteria::FilterForUserAccess < Filters::Criteria::Base
  def applies? = true

  def apply(scope)
    scope.joins(:project).merge(viewable_project_scope)
  end
end
