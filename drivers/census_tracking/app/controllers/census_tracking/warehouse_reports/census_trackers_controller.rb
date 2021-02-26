###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking::WarehouseReports
  class CensusTrackersController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    before_action :filter
    before_action :report
    before_action :set_modal_size

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

    def details
      @key = details_params[:key]
      case details_params[:row]
      when 'project'
        project_id = details_params[:project].to_i
        @project_name = GrdaWarehouse::Hud::Project.viewable_by(current_user).find(project_id)&.safe_project_name
      when 'type'
        @type = details_params[:type]
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

    private def details_params
      params.permit(
        :row,
        :type,
        :project,
        :key,
      )
    end

    private def set_modal_size
      @modal_size = :xl
    end
  end
end
