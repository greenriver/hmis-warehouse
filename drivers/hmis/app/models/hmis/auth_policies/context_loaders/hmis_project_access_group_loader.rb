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
    def initialize(data_source_id:)
      @data_source_id = data_source_id
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

      # Ensure that projects belong to the correct data source.
      # This prevents cross-data-source leakage. A user should not be authorized to view the resource if it
      # belongs to a different data source from where the request is coming from, *even if* that user does have permission to view it.
      validate_data_source!(new_project_ids)

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

    private

    def validate_data_source!(project_ids)
      valid_project_ids = Hmis::Hud::Project.where(id: project_ids, data_source_id: @data_source_id).pluck(:id)
      invalid_project_ids = project_ids - valid_project_ids
      raise ArgumentError, "Project(s) not in data source #{@data_source_id}: #{invalid_project_ids.sort.join(', ')}" if invalid_project_ids.any?
    end

    def active_access_group_ids
      @active_access_group_ids ||= Set.new(Hmis::AccessGroup.pluck(:id))
    end
  end
end
