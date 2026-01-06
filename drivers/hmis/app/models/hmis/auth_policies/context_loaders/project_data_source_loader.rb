###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

# Loads and caches data source IDs for projects. Used as a secondary guard
# to ensure users only access records in their current HMIS session.
module Hmis::AuthPolicies::ContextLoaders
  class ProjectDataSourceLoader
    def initialize
      # {project_id => data_source_id, ...}
      @cache = {}
    end

    def get(project_id)
      return nil unless project_id

      preload([project_id]) unless @cache.key?(project_id)
      @cache[project_id]
    end

    def preload(project_ids)
      return if project_ids.empty?

      new_project_ids = project_ids.uniq.compact - @cache.keys
      return if new_project_ids.empty?

      results = hmis_projects_scope.where(id: new_project_ids).pluck(:id, :data_source_id).to_h
      @cache.merge!(results)

      # For projects that don't exist in any HMIS data source, add `nil` to the cache so we don't check the db again
      no_project_ids = new_project_ids - results.keys
      @cache.merge!(no_project_ids.index_with(nil))
    end

    private

    def hmis_projects_scope
      Hmis::Hud::Project.hmis
    end
  end
end
