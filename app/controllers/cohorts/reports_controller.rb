###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cohorts
  class ReportsController < ApplicationController
    before_action :require_can_manage_cohorts!
    before_action :set_cohort

    def show
      start = report_params[:range].try(:[], :start) || 1.month.ago.to_date
      end_date = report_params[:range].try(:[], :end) || Date.tomorrow
      @range = ::Filters::DateRange.new(start: start, end: end_date)
      @changes = cohort_client_change_scope.where(changed_at: @range.range).
        order(changed_at: :desc).
        preload(:user, cohort_client: :client)
      respond_to do |format|
        format.html
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Changes to #{@cohort.name}.xlsx"
        end
      end
    end

    def set_cohort
      @cohort = cohort_source.find(params[:cohort_id].to_i)
    end

    def cohort_source
      GrdaWarehouse::Cohort
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
