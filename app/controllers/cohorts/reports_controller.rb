###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Cohorts
  class ReportsController < ApplicationControllerV2
    include CohortAuthorization
    before_action :load_cohort
    authorize_with { cohort_policy.can_view_changes_report? }

    def show
      @excel_export = GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.new
      start = report_params[:range].try(:[], :start) || 1.month.ago.to_date
      end_date = report_params[:range].try(:[], :end) || Date.tomorrow
      @range = ::Filters::DateRange.new(start: start, end: end_date)
      # changed_at is a datetime column; comparing it to bare Date bounds casts the upper bound to
      # midnight, silently excluding same-day changes made after midnight UTC (i.e. evening Eastern).
      @changes = cohort_client_change_scope.where(changed_at: @range.first.beginning_of_day..@range.last.end_of_day).
        order(changed_at: :desc).
        preload(:user, cohort_client: :client)
      current_user.policy_context.preload_client_dependencies(@changes.map { |c| c.cohort_client&.client_id })
      respond_to do |format|
        format.html
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Changes to #{@cohort.name}.xlsx"
        end
      end
    end

    def cohort_id
      params[:cohort_id].to_i
    end

    def cohort_client_change_scope
      GrdaWarehouse::CohortClientChange.where(cohort_id: @cohort.id)
    end

    def report_params
      params.permit(
        range: [:start, :end],
      )
    end
  end
end
