###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HudFilterBase < FilterBase
    include ArelHelper
    validates_presence_of :coc_codes

    # Force people to choose project types because they are additive with projects
    attribute :default_project_type_codes, Array, default: []
    # Provide a mechanism to limit relevant project types
    attribute :relevant_project_types, Array, default: []

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

      if coc_codes&.any?(&:present?)
        @effective_project_ids = GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_codes).
          joins(:project).
          where(p_t[:id].in(@effective_project_ids)).
          distinct.
          pluck(p_t[:id])
      end

      # filter any projects for acceptable types if set
      @effective_project_ids &= relevant_project_ids if relevant_project_types.any?

      # Add an invalid id if there are none
      @effective_project_ids = [0] if @effective_project_ids.empty?

      @effective_project_ids.uniq.reject(&:blank?)
    end

    # Limit the effective project ids to only those with enrollments that overlap the report range
    # OR
    # Projects with operating dates overlapping the range.
    # Looking for both of these will enable reporting on non-HMIS participating projects open during
    # the report range, and will allow the data quality checks for enrollments that are open
    # outside of the operating end dates
    def effective_project_ids_during_range(effective_range)
      @effective_project_ids_during_range ||= {}
      @effective_project_ids_during_range[effective_range] ||= begin
        ids_with_enrollments = GrdaWarehouse::Hud::Project.
          where(id: effective_project_ids).
          joins(:enrollments).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(effective_range)).
          distinct.
          pluck(:id)
        ids_for_open_projects = GrdaWarehouse::Hud::Project.
          where(id: effective_project_ids).
          active_during(effective_range).
          pluck(:id)
        (ids_with_enrollments + ids_for_open_projects).uniq
      end

      @effective_project_ids_during_range[effective_range]
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

    private def relevant_project_ids
      GrdaWarehouse::Hud::Project.with_hud_project_type(relevant_project_types).pluck(:id)
    end
  end
end
