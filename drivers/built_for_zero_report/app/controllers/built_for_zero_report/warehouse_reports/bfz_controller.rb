###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport::WarehouseReports
  class BfzController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @start_date = report_params[:start_date]&.to_date || Date.current.prev_month.beginning_of_month
      @end_date = report_params[:end_date]&.to_date || Date.current.prev_month.end_of_month
      @section_key = report_params[:section]
      @section = sections[@section_key]&.new(@start_date, @end_date)
    end

    def report_params
      return {} unless params[:report].present?

      params.require(:report).permit(
        :start_date,
        :end_date,
        :section,
      )
    end

    def sections
      {
        'adults' => ::BuiltForZeroReport::Adults,
        'chronic' => ::BuiltForZeroReport::Chronic,
        'families' => ::BuiltForZeroReport::Families,
        'veterans' => ::BuiltForZeroReport::Veterans,
        'youth' => ::BuiltForZeroReport::Youth,
      }.freeze
    end
  end
end
