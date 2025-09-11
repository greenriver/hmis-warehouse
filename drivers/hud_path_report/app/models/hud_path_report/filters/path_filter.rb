###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Filters
  class PathFilter < ::Filters::HudFilterBase
    def default_project_type_codes
      path_project_types
    end

    def path_project_types_for_select
      HudUtilityCurrent.project_type_group_titles.select { |k, _| k.in?(path_project_types) }.invert.freeze
    end

    def path_project_type_ids
      path_project_types.map { |s| HudUtilityCurrent.performance_reporting[s] }.flatten
    end

    def path_project_types
      HudUtilityCurrent.path_project_type_codes
    end
  end
end
