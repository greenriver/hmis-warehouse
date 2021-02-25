###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking::WarehouseReports
  class CensusTrackersController < ApplicationController
    include WarehouseReportAuthorization
    before_action :filter
    before_action :report

    def index
      respond_to do |format|
        format.html do
        end
        format.xlsx do
          filename = "Census Tracking Worksheet - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id)
      @filter.set_from_params(report_params)
    end

    private def report
      @report = CensusTracking::Worksheet.new(@filter)
    end

    private def report_params
      return nil unless params[:filters].present?

      params.require(:filters).permit(
        :on,
        data_source_ids: [],
        coc_codes: [],
        organization_ids: [],
        project_ids: [],
        project_group_ids: [],
        races: [],
        ethnicities: [],
        genders: [],
        veteran_statuses: [],
      )
    end
  end
end
