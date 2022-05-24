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
        format.xlsx do
          # BaseFilters tries really hard to set the user_id, but in this case, sometimes
          # we don't want it
          @filter.user_id = filter_params[:filters][:user_id]
          @report = AccessLogs::Report.new(filter: @filter, cas_user_id: @cas_user_id)
          # Set the CAS user ID on the report because it's not on the filter object
          @report.cas_user_id = filter_params[:filters]['cas_user_id']

          filename = "Access Logs #{Time.current.to_s(:db)}"
          headers['Content-Disposition'] = "attachment; filename=#{filename}.xlsx"
        end
      end
    end

    private def filter_class
      ::Filters::FilterBase
    end

    def filter_params
      return { filters: { start: 3.months.ago.to_date, end: 1.days.ago.to_date } } unless params[:filters].present?

      clean = params.permit(filters: [:user_id, :cas_user_id] + @filter.known_params)
      clean[:filters][:enforce_one_year_range] = false
      clean
    end
    helper_method :filter_params
  end
end
