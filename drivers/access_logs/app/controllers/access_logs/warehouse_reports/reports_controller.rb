###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AccessLogs::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include BaseFilters

    def index
      respond_to do |format|
        format.html {}
        format.csv do
          # BaseFilters tries really hard to set the user_id, but in this case, sometimes
          # we don't want it
          @filter.user_id = filter_params[:filters][:user_id]
          @report = AccessLogs::Report.new(filter: @filter)
          filename = "Access Logs #{Time.current.to_s(:db)}.csv"

          send_data @report.csv, filename: filename, type: 'text/csv'
        end
      end
    end

    private def filter_class
      ::Filters::FilterBase
    end

    def filter_params
      return {} unless params[:filters].present?

      clean = params.permit(filters: [:user_id] + @filter.known_params)
      clean[:filters][:enforce_one_year_range] = false
      clean
    end
    helper_method :filter_params
  end
end
