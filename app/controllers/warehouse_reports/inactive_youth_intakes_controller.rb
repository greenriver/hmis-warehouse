###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class InactiveYouthIntakesController < ApplicationController
    include AjaxModalRails::Controller

    before_action :set_filter
    before_action :set_report

    def index
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id)
      if filter_params[:filters].blank?
        @filter.start = 3.months.ago.beginning_of_month.to_date
        @filter.end = 1.days.ago.to_date
      end
      @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?
    end

    private def set_report
      @report = report_class.new(@filter)
    end

    def filter_params
      params.permit(
        filters: [
          :start,
          :end,
        ],
      )
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def report_class
      GrdaWarehouse::WarehouseReports::Youth::InactiveIntake
    end
  end
end
