###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Project
  class DataQualitiesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter, only: [:show, :create]
    before_action :set_projects, :set_current_reports, only: [:show]
    before_action :set_history_filter, only: [:history]

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
      @reports = filtered_report_scope.
        order(id: :desc).
        preload(project: [:organization, :data_source])
      @pagy, @reports = pagy(@reports, items: 50)
    end

    def create
      errors = []
      @generate = generate_param == 1
      @email = email_param == 1
      errors << 'A date range is required' if date_range_params[:start].blank? || date_range_params[:end].blank?
      @range = ::Filters::DateRange.new(date_range_params)
      @range.validate
      begin
        @project_ids = project_params
        # filter by viewability
        @project_ids = project_scope.where(id: @project_ids).pluck(:id)
        @project_group_ids = project_group_params

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
            notify_contacts: @email,
          )
        elsif @email
          report = report_scope.
            where(id_column => id).
            order(id: :desc).first_or_initialize
          if report.persisted?
            report.update(notify_contacts: @email)
            report.send_notifications
          end
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

    private def set_history_filter
      @history_filter = ::Filters::FilterBase.new(
        initial_filter_params.merge(
          user_id: current_user.id,
          default_start: Date.current - 3.months,
          default_end: Date.tomorrow,
        ),
      )
    end

    def generate_param
      params.permit(project_data_quality: [:generate])[:project_data_quality][:generate].try(:to_i)
    end

    def email_param
      params.permit(project_data_quality: [:email])[:project_data_quality][:email].try(:to_i)
    end

    def project_params
      return [] unless params[:project].present?

      params.require(:project).keys.map(&:to_i)
    end

    def project_group_params
      return [] unless params[:project_group].present?

      params.require(:project_group).keys.map(&:to_i)
    end

    def date_range_params
      params.require(:project_data_quality).
        permit([:start, :end])
    end

    private def initial_filter_params
      return {} unless params[:filters]

      params.require(:filters).permit(::Filters::FilterBase.new(user_id: current_user.id).known_params)
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

      @pagy, @project_scope = pagy(@projects, items: 50)
      @projects = @project_scope.
        group_by { |p| [p.data_source.short_name, p.organization] }
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization.viewable_by(current_user)
    end

    def project_scope
      if current_user.can_view_confidential_project_names?
        GrdaWarehouse::Hud::Project.viewable_by(current_user)
      else
        GrdaWarehouse::Hud::Project.viewable_by(current_user).non_confidential
      end
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
      url = url_for(action: :show, only_path: true).sub(/^\//, '')
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

    private def filtered_report_scope
      scope = report_scope.where(started_at: (@history_filter.start..@history_filter.end))

      scope = scope.where(project_id: project_scope.select(:id)).
        or(scope.where(project_group_id: project_group_scope.select(:id)))

      if can_view_all_reports?
        creator_user_id = @history_filter.creator_id.presence
        scope = scope.where(requestor_id: creator_user_id) if creator_user_id
      else
        scope = scope.where(requestor_id: current_user.id)
      end

      project_ids = @history_filter.project_ids
      scope = scope.where(project_id: project_ids.uniq) if project_ids&.any?

      project_group_ids = @history_filter.project_group_ids
      scope = scope.where(project_group_id: project_group_ids.uniq) if project_group_ids&.any?

      scope
    end

    private def available_users
      creator_user_ids = report_scope.distinct.pluck(:requestor_id)
      User.active.where(id: creator_user_ids)
    end
    helper_method :available_users
  end
end
