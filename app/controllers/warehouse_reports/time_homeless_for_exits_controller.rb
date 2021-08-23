###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class TimeHomelessForExitsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter
    before_action :set_report

    def index
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id, project_type_codes: [])
      if filter_params[:filters].blank?
        @filter.start = 1.month.ago.beginning_of_month.to_date
        @filter.end = @filter.start.end_of_month.to_date
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
          :sub_population,
          cohort_ids: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
          coc_codes: [],
        ],
      )
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def report_class
      GrdaWarehouse::WarehouseReports::TimeHomelessForExit
    end
  end
end
