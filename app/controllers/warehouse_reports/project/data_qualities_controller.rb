###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Project
  class DataQualitiesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter, only: [:show, :create]
    before_action :set_projects, :set_current_reports, only: [:show]

    def show
      @project_report_shells = report_base_class.where.not(project_id: nil).
        where(project_id: @project_scope.select(:id)).
        select(report_base_class.column_names - ['report', 'support']).
        order(id: :asc).
        index_by(&:project_id)
      @project_group_report_shells = report_base_class.where.not(project_group_id: nil).
        where(project_group_id: @project_groups.select(:id)).
        select(report_base_class.column_names - ['report', 'support']).
        order(id: :asc).
        index_by(&:project_group_id)

      if Date.current.month < 10
        start_date = Date.new(Date.current.year - 2, 10, 1)
        end_date = Date.new(Date.current.year - 1, 9, 30)
      else
        start_date = Date.new(Date.current.year - 1, 10, 1)
        end_date = Date.new(Date.current.year, 9, 30)
      end
      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
    end

    def history
      @project_reports = report_scope.joins(:project).merge(project_scope).
        order(created_at: :desc).
        page(params[:page]).per(50)

      @project_group_reports = report_scope.joins(:project_group).merge(project_group_scope).
        order(created_at: :desc).
        page(params[:page]).per(50)
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
        redirect_to({ action: :show }.merge(@filter.for_params))
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
      render xlsx: 'download', filename: "project_data_quality_report #{Date.current}.xlsx"
    end

    private def set_filter
      @filter = ::Filters::FilterBase.new(initial_filter_params.merge(user_id: current_user.id, project_type_codes: []))
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

    private def initial_filter_params
      return {} unless params[:filters]

      params.require(:filters).
        permit(
          coc_codes: [],
          project_types: [],
          project_type_numbers: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
        )
    end

    private def set_projects
      project_ids = @filter.anded_effective_project_ids
      @projects = if project_ids&.any?

        project_scope.where(id: project_ids).
          joins(:organization, :data_source).
          order(p_t[:data_source_id].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc).
          preload(:contacts, :data_source, organization: :contacts)
      else
        project_scope.none
      end
      # Load any matching project groups before paginating projects
      @project_groups = project_group_scope.joins(:projects).
        merge(@projects).
        order(name: :asc).
        preload(:contacts, projects: [organization: :contacts])

      @project_scope = @projects.page(params[:page]).per(50)
      @projects = @project_scope.
        group_by { |p| [p.data_source.short_name, p.organization] }
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization.viewable_by(current_user)
    end

    def project_scope
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

    def project_group_scope
      GrdaWarehouse::ProjectGroup.viewable_by(current_user)
    end

    # The version of the report we are currently generating
    def report_scope
      GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFour
    end

    def report_base_class
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base
    end

    def related_report
      url = url_for(action: :show, only_path: true).sub(%r{^/}, '')
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url)
    end

    private def set_current_reports
      @current_reports = report_scope.
        where.not(project_id: nil).
        order(id: :asc).
        index_by(&:project_id)
      @current_project_group_reports = report_scope.
        where.not(project_group_id: nil).
        order(id: :asc).
        index_by(&:project_group_id)
    end
  end
end
