###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class DeclineReasonController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @report = WarehouseReport::CasDeclines.new(start_date: @range.start, end_date: @range.end)

      respond_to do |format|
        format.html
        format.xlsx
      end
    end

    def set_range
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: 13.month.ago.to_date,
          end: 1.months.ago.to_date,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
    end

    def report_source
      GrdaWarehouse::CasReport
    end
  end
end
