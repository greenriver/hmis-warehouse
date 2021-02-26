###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking::WarehouseReports
  class CensusTrackersController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper
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
      query = @report.populations[@key]
      case details_params[:row]
      when 'project'
        project_id = details_params[:project].to_i
        @project_name = GrdaWarehouse::Hud::Project.viewable_by(current_user).find(project_id)&.safe_project_name
        @clients = @report.clients_by_project(project_id, query)
      when 'type'
        @type = details_params[:type]
        @clients = @report.clients_by_project_type(@type, query)
      else
        @clients = @report.clients_by_population(query)
      end
      @clients = @clients.order(she_t[:project_name], c_t[:LastName], c_t[:FirstName]).pluck(detail_columns.values)
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

    private def detail_columns
      {
        'Client ID' => she_t[:client_id],
        'First Name' => c_t[:FirstName],
        'Last Name' => c_t[:LastName],
        'Age' => shs_t[:age],
        'Project Name' => she_t[:project_name],
      }
    end
    helper_method :detail_columns

    private def set_modal_size
      @modal_size = :xl
    end
  end
end
