module WarehouseReports
  class RrhController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :available_projects
    before_action :set_filter
    

    respond_to :html, :js

    def index
      @report = WarehouseReport::RrhReport.new(
        project_id: @filter.project_id, 
        start_date: @filter.start_date, 
        end_date: @filter.end_date,
        subpopulation: @filter.subpopulation,
        household_type: @filter.household_type,
      )
    end

    def program_data
      
    end

    private def set_filter
      @filter = OpenStruct.new()
      @filter.start_date = report_params[:start_date]&.to_date rescue 1.months.ago.beginning_of_month
      @filter.end_date = report_params[:end_date]&.to_date rescue @filter.start_date.end_of_month
      @filter.subpopulation = report_params[:subpopulation]&.to_date rescue :all
      @filter.houshold_type = report_params[:household_type]&.to_date rescue :all
      p_id = report_params[:project_id] rescue nil
      @filter.project_id = project_id(p_id)
    end

    private def report_params
      params.require(:filter).permit(
        :start_date,
        :end_date,
        :project_id,
        :subpopulation,
        :household_type,
      )
    end

    private def project_id project_id
      project_id = available_projects.map(&:last).
        select{|m| m == project_id.to_i}&.first
      return project_id.to_i if project_id
      :all
    end

    private def available_projects
      @available_projects ||= project_source.with_project_type(13).
        joins(:organization).
        pluck(o_t[:OrganizationName].to_sql, :ProjectName, :id).
        map do |org_name, project_name, id|
          ["#{project_name} >> #{org_name}", id]
        end
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

  end
end
