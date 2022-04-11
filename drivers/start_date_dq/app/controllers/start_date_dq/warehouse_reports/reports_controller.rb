###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StartDateDq::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include BaseFilters
    include Filter::FilterScopes

    before_action :set_report

    def index
      respond_to do |format|
        format.html do
          if params[:filter].present?
            data = @report.data
            @pagy, @enrollments = pagy(data, items: 50)
          end
        end
        format.xlsx do
          @enrollments = @report.data
        end
      end
    end

    private def set_report
      @filter = filter_class.new(
        user_id: current_user.id,
        default_start: Date.current - 3.months,
        default_end: Date.current,
      ).set_from_params(filter_params)
      @report = report_class.new(current_user.id, @filter)
    end

    private def report_class
      StartDateDq::Report
    end

    def filter_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(filter_class.new.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
