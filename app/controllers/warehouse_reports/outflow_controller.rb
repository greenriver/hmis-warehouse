###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class OutflowController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @filter = ::Filters::DateRangeWithSubPopulation.new(filter_options)
    end

    private def filter_options
      if params[:filter].present?
        opts = params.require(:filter).permit(:start, :end, :sub_population)
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

    private def default_start
      3.months.ago.beginning_of_month
    end

    private def default_end
      1.months.ago.end_of_month
    end
  end
end