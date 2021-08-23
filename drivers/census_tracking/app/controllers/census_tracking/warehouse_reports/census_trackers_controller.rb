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
          flash[:error] = 'You must select one or more organizations, projects, or project groups' if params[:commit].present? && ! @show_report
        end
        format.xlsx do
          filename = "Census Tracking Worksheet - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def details
      @key = details_params[:key]
      project_id = details_params[:project].to_i
      @project_name = GrdaWarehouse::Hud::Project.viewable_by(current_user).find(project_id)&.safe_project_name
      @clients = @report.clients_by_project(project_id, @key).
        sort_by { |client| [client.project_name, client.last_name, client.first_name] }
    end

    private def filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id, project_type_codes: [])
      @filter.set_from_params(report_params)
      @show_report = @filter.project_ids.present? || @filter.project_group_ids.present? || @filter.organization_ids.present?
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
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'Age' => :age,
        'Project Name' => :project_name,
      }
    end
    helper_method :detail_columns

    private def set_modal_size
      @modal_size = :xl
    end
  end
end
