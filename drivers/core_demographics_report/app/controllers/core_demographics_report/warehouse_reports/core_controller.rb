###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport::WarehouseReports
  class CoreController < ApplicationController
    include WarehouseReportAuthorization
    include PjaxModalController
    include ArelHelper

    before_action :set_filter

    def index
    end

    private def set_filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id)
      @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?
    end

    private def filter_params
      params.permit(
        filters: [
          :start,
          :end,
          coc_codes: [],
          project_ids: [],
          project_group_ids: [],
        ],
      )
    end
  end
end
