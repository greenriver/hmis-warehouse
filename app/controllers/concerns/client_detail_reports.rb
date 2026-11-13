###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientDetailReports
  extend ActiveSupport::Concern

  PERMITTED_FILTER_PARAMS = [
    :start,
    :end,
    :sub_population,
    :hoh_only,
    :ph,
    {
      genders: [],
      races: [],
      age_ranges: [],
      organization_ids: [],
      project_ids: [],
      project_group_ids: [],
      project_type_codes: [],
      coc_codes: [],
    },
  ].freeze

  def self.permitted_filter_keys
    PERMITTED_FILTER_PARAMS.flat_map { |param| param.is_a?(Hash) ? param.keys : param }
  end

  # Used when the request has no filter at all; any submitted filter replaces it entirely.
  def self.default_filter_params
    { project_type_codes: HudHelper.util.homeless_project_type_codes }
  end

  # Shared with the background renders and PDF exports so they report the same rows as the page.
  def self.build_filter(user_id:, filter_params:)
    ::Filters::FilterBase.new(
      user_id: user_id,
      enforce_one_year_range: false,
      project_type_codes: [],
    ).set_from_params(filter_params)
  end

  included do
    private def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user, permission: :can_view_assigned_reports))
    end

    private def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    private def filter_params
      return ClientDetailReports.default_filter_params unless params[:filter].present?

      params.require(:filter).permit(*PERMITTED_FILTER_PARAMS)
    end

    private def set_filter
      @filter = ClientDetailReports.build_filter(user_id: current_user.id, filter_params: filter_params)
    end
  end
end
