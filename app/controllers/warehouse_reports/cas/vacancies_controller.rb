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
            start: default_start_date,
            end: default_end_date,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
    end

    def default_start_date
      default_end_date - 1.years + 1.days
    end

    def default_end_date
      if Date.today.month > 6
        year = Date.today.year
      else
        year = Date.today.year - 1.years
      end
      Date.new(year, 6, 30)
    end
  end
end