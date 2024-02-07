###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HistoryFilter
  extend ActiveSupport::Concern

  # NOTE: path_for_clear_view_filter must be defined in the including controller
  # and added as a helper method.  Usually it's just the index path for the controller.
  # Additionally, you'll need to add apply_view_filters(reports) to limit the reports shown.

  included do
    before_action :set_view_filter, only: [:index]

    private def view_filter_params
      params.permit(
        :history_filter_creator,
        :history_filter_start,
        :history_filter_end,
      )
    end

    private def set_view_filter
      defaults = {
        history_filter_creator: 'all',
        history_filter_start: (Date.current - 6.months).to_s,
        history_filter_end: Date.current.to_s,
      }
      @view_filter = {}
      @view_filter[:history_filter_creator] = view_filter_params[:history_filter_creator] || defaults[:history_filter_creator]
      @view_filter[:history_filter_start] = view_filter_params[:history_filter_start] || defaults[:history_filter_start]
      @view_filter[:history_filter_end] = view_filter_params[:history_filter_end] || defaults[:history_filter_end]
      @active_filter = @view_filter != defaults
    end

    def apply_view_filters(reports)
      if can_view_all_reports?
        # Only apply a user filter if you have chosen one if you can see all reports
        reports = reports.where(user_id: @view_filter[:history_filter_creator]) if @view_filter.try(:[], :history_filter_creator).present? && @view_filter[:history_filter_creator] != 'all'
      else
        reports = reports.where(user_id: current_user.id)
      end
      return reports unless @view_filter.present?

      filter_range = Time.zone.parse(@view_filter[:history_filter_start]) .. (Time.zone.parse(@view_filter[:history_filter_end]) + 1.days)
      reports.where(created_at: filter_range)
    end

    private def view_filter_available_users
      [['all', 'Any user']] + User.active.where(id: report_scope.pluck(:user_id)).map { |u| [u.id, u.name_with_email] }
    end
    helper_method :view_filter_available_users
  end
end
