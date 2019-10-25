###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Project
  class DataQualitiesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_projects, :set_project_groups, :load_data_quality_report_shells

    def show
      if Date.current.month < 10
        start_date = Date.new(Date.current.year - 2, 10, 1)
        end_date = Date.new(Date.current.year - 1, 9, 30)
      else
        start_date = Date.new(Date.current.year - 1, 10, 1)
        end_date = Date.new(Date.current.year, 9, 30)
      end
      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
    end

    # TODO: rewrite this so we aren't using errors as flow control
    def create
      errors = []
      @generate = generate_param == 1
      @email = email_param == 1
      errors << 'A date range is required' if date_range_params[:start].blank? || date_range_params[:end].blank?
      @range = ::Filters::DateRange.new(date_range_params)
      @range.validate
      begin
        @project_ids = begin
          project_params
        rescue StandardError
          []
        end
        # filter by viewability
        @project_ids = project_scope.where(id: @project_ids).pluck(:id)
        @project_group_ids = begin
          project_group_params
        rescue StandardError
          []
        end
        raise ActionController::ParameterMissing, 'Parameters missing' if @project_ids.empty? && @project_group_ids.empty?
      rescue ActionController::ParameterMissing
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
          report_scope.create(
            id_column => id,
            start: @range.start,
            end: @range.end,
            requestor_id: current_user.id,
          )
        else
          report_scope.
            where(id_column => id).
            order(id: :desc).first_or_initialize
        end
        # Reporting::RunProjectDataQualityJob.perform_later(report_id: report.id, generate: @generate, send_email: @email)
      end
    end

    def download
      @report = []
      @projects = project_scope.includes(:organization, :data_source).
        joins(:organization).
        preload(:contacts, :current_data_quality_report).
        order(p_t[:data_source_id].asc, o_t[:OrganizationID].asc)

      @project_groups = project_group_scope.includes(projects: [:organization, :data_source]).
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
      render xlsx: :download, filename: "project_data_quality_report #{Date.current}.xlsx"
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
      GrdaWarehouse::ProjectGroup.viewable_by current_user
    end

    # The version of the report we are currently generating
    def report_scope
      GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFour
    end

    def report_base_class
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base
    end

    def set_projects
      @projects = project_scope.joins(:organization, :data_source).
        order(p_t[:data_source_id].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc).
        preload(:contacts, :data_source, organization: :contacts).
        group_by { |m| [m.data_source.short_name, m.organization] }
    end

    def set_project_groups
      @project_groups = project_group_scope.includes(:projects).
        order(name: :asc).
        preload(:contacts, projects: [organization: :contacts])
    end

    def load_data_quality_report_shells
      @project_report_shells = report_base_class.where.not(project_id: nil).
        select(report_base_class.column_names - ['report', 'support']).
        order(id: :asc).
        index_by(&:project_id)
      @project_group_report_shells = report_base_class.where.not(project_group_id: nil).
        select(report_base_class.column_names - ['report', 'support']).
        order(id: :asc).
        index_by(&:project_group_id)
    end

    def related_report
      url = url_for(action: :show, only_path: true).sub(%r{^/}, '')
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url)
    end
  end
end
