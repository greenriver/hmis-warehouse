module WarehouseReports::Project
  class DataQualitiesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_projects, :set_project_groups

    def show
      start_date = Date.new(Date.today.year-2,10,1)
      end_date = Date.new(Date.today.year-1,9,30)
      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
    end

    def create
      errors = []
      @generate = generate_param == 1
      @email = email_param == 1
      if date_range_params[:start].blank? || date_range_params[:end].blank?
        errors << 'A date range is required'
      end
      @range = ::Filters::DateRange.new(date_range_params)
      @range.validate
      begin
        @project_ids = project_params rescue []
        # filter by viewability
        @project_ids = current_user.projects.where( id: @project_ids ).pluck(:id)   
        @project_group_ids = project_group_params rescue []
        if @project_ids.empty? && @project_group_ids.empty?
          raise ActionController::ParameterMissing, 'Parameters missing'
        end
      rescue ActionController::ParameterMissing => e
        errors << 'At least one project or project group must be selected'
      end
      if errors.any?
        flash[:error] = errors.join('<br />'.html_safe)
        render action: :show
      else
        # kick off report generation
        queue_report(id_column: :project_id, keys: @project_ids)
        queue_report(id_column: :project_group_id, keys: @project_group_ids)
        redirect_to action: :show
      end
    end

    def queue_report(id_column:, keys:)
      keys.each do |id|
        if @generate
          report = report_scope.create(
            id_column => id, 
            start: @range.start, 
            end: @range.end
          )
        else
          report = report_scope.
            where(id_column => id).
            order(id: :desc).first_or_initialize
        end
        Reporting::RunProjectDataQualityJob.perform_later(report_id: report.id, generate: @generate, send_email: @email)
      end
    end

    def download
      @report = []
      @projects = project_scope.includes(:organization, :data_source).
        joins(:organization).
        preload(:contacts, :current_data_quality_report).
        order(p_t[:data_source_id].asc, o_t[:OrganizationID].asc)
        
      @project_groups = project_group_scope.includes(projects: :organization, projects: :data_source).
        joins(projects: :organization).
        preload(:contacts, :current_data_quality_report).
        order(p_t[:data_source_id].asc, o_t[:OrganizationID].asc)        
      @projects.each do |project|
        last_report = project.current_data_quality_report
        @report << last_report if last_report.present?
      end
      @project_groups.each do |project|
        last_report = project.current_data_quality_report
        @report << last_report if last_report.present?
      end
      render xlsx: :download, filename: "project_data_quality_report #{Date.today}.xlsx"
    end

    def generate_param
      params.permit(project_data_quality: [:generate])[:project_data_quality][:generate].try(:to_i)
    end

    def email_param
      params.permit(project_data_quality: [:email])[:project_data_quality][:email].try(:to_i)
    end

    def project_params
      params.require(:project).keys.map(&:to_i)
    end

    def project_group_params
      params.require(:project_group).keys.map(&:to_i)
    end

    def date_range_params
      params.require(:project_data_quality).
        permit([:start, :end])
    end

    def project_scope
      GrdaWarehouse::Hud::Project.viewable_by current_user
    end

    def project_group_scope
      GrdaWarehouse::ProjectGroup.all
    end

    # The version of the report we are currently generating
    def report_scope
      GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionTwo
    end

    def set_projects
      @projects = project_scope.joins(:organization, :data_source).
        order("#{p_t[:data_source_id].asc.to_sql}, #{o_t[:OrganizationName].asc.to_sql}, #{p_t[:ProjectName].asc.to_sql}").
        preload(:contacts, :data_quality_reports).
        group_by{ |m| [m.data_source.short_name, m.organization]}
    end

    def set_project_groups
      @project_groups = project_group_scope.includes(:projects).
        order(name: :asc).
        preload(:contacts, :data_quality_reports)
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/project/data_quality')
    end
  end
end
