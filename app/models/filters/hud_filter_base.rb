###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HudFilterBase < FilterBase
    validates_presence_of :coc_codes

    # Force people to choose project types because they are additive with projects
    def default_project_type_codes
      []
    end

    # NOTE: This differs from the base filter class because it doesn't include any projects based on CoCCode
    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_project_types

      # TODO: determine which projects should be excluded/included based on chosen funding sources (include all if no funding sources present) and remove from effective_project_ids

      # Add an invalid id if there are none
      @effective_project_ids = [0] if @effective_project_ids.empty?

      @effective_project_ids.uniq.reject(&:blank?)
    end

    def apply(scope)
      # @filter is required for these to work
      @filter = self
      scope = filter_for_user_access(scope)
      scope = filter_for_projects_hud(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_sub_population(scope)

      scope
    end

    private def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end
  end
end
