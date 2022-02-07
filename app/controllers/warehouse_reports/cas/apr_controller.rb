###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class AprController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @report = WarehouseReport::CasApr.new(start_date: @range.start, end_date: @range.end)
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = 'CAS APR.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def set_range
      date_range_options = range_params[:range]
      unless date_range_options.present?
        date_range_options = {
          start: default_start_date,
          end: default_end_date,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
    end

    def range_params
      params.permit(range: [:start, :end])
    end
    helper_method :range_params

    def default_start_date
      default_end_date - 1.years + 1.days
    end

    def default_end_date
      if Date.current.month > 6
        year = Date.current.year
      else
        year = Date.current.year - 1
      end
      Date.new(year, 6, 30)
    end

    def report_source
      GrdaWarehouse::CasReport
    end
  end
end
