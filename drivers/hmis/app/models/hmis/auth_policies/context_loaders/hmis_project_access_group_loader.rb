###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

# Loads and caches access group IDs for projects, including via organizations, data sources,
# and project groups.
module Hmis::AuthPolicies::ContextLoaders
  class HmisProjectAccessGroupLoader
    def initialize
      # {project_id => [access_group_id,...], ...}
      @cache = {}
    end

    def get(project_id)
      preload([project_id]) unless @cache.key?(project_id)
      @cache[project_id] || []
    end

    def preload(project_ids)
      return if project_ids.empty?

      new_project_ids = project_ids.uniq - @cache.keys
      return if new_project_ids.empty?

      results = Hmis::ProjectAccessGroupMember.
        where(project_id: new_project_ids).
        pluck(:project_id, :access_group_id).
        group_by(&:shift).
        transform_values { |v| v.flatten.compact_blank }
      @cache.merge!(results)
    end
  end
end
