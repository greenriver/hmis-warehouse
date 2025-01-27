module Filters::Components
  ProjectIdFilter = Struct.new(:label, :project_ids, :project_group_ids, keyword_init: true) do
    def apply(scope)
      return scope if project_ids.blank?

      scope.in_project(project_ids.uniq)
    end
  end
end
