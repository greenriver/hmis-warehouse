###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Filters
  class PathFilter < ::Filters::HudFilterBase
    def default_project_type_codes
      path_project_types
    end

    def path_project_types_for_select
      GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.select { |k, _| k.in?(path_project_types) }.invert.freeze
    end

    def path_project_type_ids
      path_project_types.map { |s| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[s] }.flatten
    end

    def path_project_types
      GrdaWarehouse::Hud::Project::PATH_PROJECT_TYPE_CODES
    end
  end
end
