###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDetailReports
  extend ActiveSupport::Concern

  included do
    private def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user, permission: :can_view_assigned_reports))
    end

    private def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    private def filter_params
      # default to homeless project types, but don't set it if we have any sort of filter set
      return { project_type_codes: HudUtility2024.homeless_project_type_codes } unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        :sub_population,
        :hoh_only,
        :ph,
        genders: [],
        races: [],
        age_ranges: [],
        organization_ids: [],
        project_ids: [],
        project_group_ids: [],
        project_type_codes: [],
        coc_codes: [],
      )
    end

    private def set_filter
      @filter = ::Filters::FilterBase.new(
        user_id: current_user.id,
        enforce_one_year_range: false,
        project_type_codes: [],
      ).set_from_params(filter_params)
    end
  end
end
