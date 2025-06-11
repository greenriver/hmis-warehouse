###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::ProjectConfigFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_config_type)).
      yield_self(&method(:with_project))
  end

  protected

  def with_config_type(scope)
    with_filter(scope, :config_type) do
      scope.with_config_type(input.config_type)
    end
  end

  def with_project(scope)
    with_filter(scope, :project) do
      projects = Hmis::Hud::Project.where(id: input.project).preload(:organization)
      scope.for_projects(projects)
    end
  end
end
