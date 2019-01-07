module WarehouseReports
  class YouthExportController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_filter
    before_action :set_report

    def index

      @enrollments = @report.enrollments.
        order(c_t[:LastName].asc, c_t[:FirstName].asc).
        preload(client: [:source_clients, :vispdats])
      respond_to do |format|
        format.html {
          @enrollments = @enrollments.page(params[:page]).per(25)
        }
        format.xlsx {}
      end
    end

    def set_filter
      @filter = ::Filters::DateRange.new(date_filter_options)
    end

    def set_report
      @report = WarehouseReport::Youth.new(
        start_date: @filter.start, 
        end_date: @filter.end
      )

    end

    def date_filter_options
      if params[:filter].present?
        opts = params.require(:filter).permit(:start, :end)
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
