###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HudFilterBase < FilterBase
    include ArelHelper
    validates_presence_of :coc_codes

    # Force people to choose project types because they are additive with projects
    attribute :default_project_type_codes, Array, default: []

    def params_for_display
      params = known_params.flat_map do |k|
        if k.is_a?(Hash)
          k.keys
        else
          k
        end
      end
      # All HUD reports accept multiple CoC Codes (except the LSA, which doesn't currently use this)
      params - [:coc_code]
    end

    # NOTE: This differs from the base filter class because it doesn't include any projects based on CoCCode
    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_project_types

      if funder_ids.present?
        @effective_project_ids = funder_scope.where(Funder: funder_ids).
          joins(:project).
          where(p_t[:id].in(@effective_project_ids)).
          distinct.
          pluck(p_t[:id])
      end

      if coc_codes.present?
        @effective_project_ids = GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_codes).
          joins(:project).
          where(p_t[:id].in(@effective_project_ids)).
          distinct.
          pluck(p_t[:id])
      end

      # Add an invalid id if there are none
      @effective_project_ids = [0] if @effective_project_ids.empty?

      @effective_project_ids.uniq.reject(&:blank?)
    end

    def apply(scope, except: [])
      # @filter is required for these to work
      @filter = self
      filter_methods(except: except).each do |filter_method|
        scope = send(filter_method, scope)
      end
      scope
    end

    private def filter_methods(except: [])
      [
        :filter_for_user_access,
        :filter_for_projects_hud,
        :filter_for_project_cocs,
        :filter_for_veteran_status,
        :filter_for_household_type,
        :filter_for_head_of_household,
        :filter_for_age,
        :filter_for_gender,
        :filter_for_race,
        :filter_for_ethnicity,
        :filter_for_sub_population,
        :filter_for_enrollment_cocs,
      ] - Array.wrap(except)
    end

    private def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    private def funder_scope
      GrdaWarehouse::Hud::Funder
    end
  end
end
