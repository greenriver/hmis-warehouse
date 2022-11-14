###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaFollowupReport::WarehouseReports
  class YouthFollowupController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @filter = ::Filters::FilterBase.new(user_id: current_user.id).update(filter_params)
      @report = MaYyaFollowupReport::Report.new(@filter)
    end

    private def filter_params
      return [] unless params[:filter].present?

      params.require(:filter).permit(
        :on,
        age_ranges: [],
        project_ids: [],
      )
    end
  end
end
