###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Filters
  class PathFilter < ::Filters::HudFilterBase
    def default_project_type_codes
      [:so, :services_only]
    end

    def path_project_types_for_select
      GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.select { |k, _| k.in?([:so, :services_only]) }.invert.freeze
    end

    def path_project_type_ids
      [:so, :services_only].map { |s| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[s] }.flatten
    end
  end
end
