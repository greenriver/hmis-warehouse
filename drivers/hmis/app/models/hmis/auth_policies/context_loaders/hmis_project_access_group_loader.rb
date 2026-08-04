###
# Copyright Green River Data Group, Inc.
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
        transform_values do |values|
          clean_values = values.flatten.compact_blank
          # Filter out deleted access groups. ProjectAccessGroupMember can't do this due to database boundaries
          active_access_group_ids.intersection(clean_values).to_a
        end

      @cache.merge!(results)

      # For projects that don't have any access groups, add `nil` to the cache, so that we don't check the db again
      no_access_project_ids = new_project_ids - results.keys
      @cache.merge!(no_access_project_ids.index_with(nil))
    end

    # {project_id => [access_group_id, ...]} for projects in the given data source that are covered by the
    # given access groups, directly or indirectly. The inverse of #get, so results mention only the access
    # groups passed in. Deliberately doesn't populate the per-project cache, which holds every access group
    # for a project regardless of who can reach it. Deleted access groups need no filtering here, since
    # callers arrive with groups they resolved through their own access controls. IDs are sorted so that
    # projects sharing an access profile share a cache entry in HmisPermissionLoader.
    def access_group_ids_by_project(access_group_ids, data_source_id:)
      return {} if access_group_ids.empty?

      Hmis::ProjectAccessGroupMember.
        joins(:project).
        where(access_group_id: access_group_ids).
        where(Hmis::Hud::Project.arel_table[:data_source_id].eq(data_source_id)).
        pluck(:project_id, :access_group_id).
        group_by(&:first).
        transform_values { |rows| rows.map(&:last).sort }
    end

    private

    def active_access_group_ids
      @active_access_group_ids ||= Set.new(Hmis::AccessGroup.pluck(:id))
    end
  end
end
