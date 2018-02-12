module Cohorts
  class ReportsController < ApplicationController
    before_action :require_can_manage_cohorts!
    before_action :set_cohort

    def show
      @range = ::Filters::DateRange.new(report_params[:range])
      @changes = cohort_client_change_scope.where(changed_at: @range.range).
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
        range: [:start, :end]
      )
    end
  end
end