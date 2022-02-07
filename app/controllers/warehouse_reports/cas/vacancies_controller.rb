###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class VacanciesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @report = WarehouseReport::CasVacancies.new(start_date: @range.start, end_date: @range.end)
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = 'CAS Vacancies.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def set_range
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: Date.current - 1.month,
          end: Date.current,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
    end
  end
end
