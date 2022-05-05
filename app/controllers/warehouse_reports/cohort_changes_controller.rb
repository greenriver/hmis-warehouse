###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class CohortChangesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_filter
    before_action :set_report

    def index
      @enrollments = @report.cohort_enrollments.
        order(c_t[:LastName].asc, c_t[:FirstName].asc).
        preload(cohort_client: [client: [:source_clients, :vispdats]])
      respond_to do |format|
        format.html do
          @pagy, @enrollments = pagy(@enrollments)
        end
        format.xlsx {}
      end
    end

    def set_filter
      @filter = ::Filters::DateRangeAndCohort.new(filter_options)
    end

    def set_report
      @report = WarehouseReport::CohortChanges.new(
        start_date: @filter.start,
        end_date: @filter.end,
        cohort_id: @filter.cohort_id,
      )
    end

    def filter_options
      if params[:filter].present?
        opts = params.require(:filter).permit(:start, :end, :cohort_id)
        if opts[:start].to_date > opts[:end].to_date
          start = opts[:end]
          opts[:end] = opts[:start]
          opts[:start] = start
        end
        opts
      else
        {
          start: default_start.to_date,
          end: default_end.to_date,
          cohort_id: GrdaWarehouse::Cohort.active.viewable_by(current_user).first&.id,
        }
      end
    end

    def default_start
      1.months.ago.beginning_of_month
    end

    def default_end
      default_start.end_of_month
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end
