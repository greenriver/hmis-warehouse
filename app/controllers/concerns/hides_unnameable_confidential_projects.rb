###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The name policy is per project, so it can't be expressed in SQL. Only confidential projects
# are checked, and they are excluded by id so the scope stays chainable and pageable.
# The default rule is the project policy's can_view_name?; callers pass a block to use another rule.
module HidesUnnameableConfidentialProjects
  extend ActiveSupport::Concern

  private def without_unnameable_confidential_projects(scope, &nameable)
    scope.where.not(id: unnameable_confidential_project_ids(scope, &nameable))
  end

  private def unnameable_confidential_project_ids(scope, &nameable)
    nameable ||= ->(project) { current_user.policy_for(project).can_view_name? }
    confidential_projects = scope.confidential.to_a
    current_user.policy_context.preload_project_dependencies(confidential_projects.map(&:id))
    confidential_projects.reject(&nameable).map(&:id)
  end
end
