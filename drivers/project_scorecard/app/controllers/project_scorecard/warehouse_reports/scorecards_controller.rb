###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard::WarehouseReports
  class ScorecardsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_projects, :set_project_groups, :set_current_reports
    before_action :set_report, only: [:show, :edit, :update]

    def index
      start_date = Date.current.prev_month.beginning_of_month
      end_date = Date.current.prev_month.end_of_month

      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
    end

    def for_project
      project = project_scope.find(params[:project_id].to_i)
      @name = project.name
      @reports = reports_scope.where(project_id: project.id)
      render :report_list
    end

    def for_group
      project_group = project_group_scope.find(params[:project_group_id].to_i)
      @name = project_group.name
      @reports = reports_scope.where(project_group_id: project_group.id)
      render :report_list
    end

    def create
      @generate = create_parameters[:generate] == '1'
      @email = create_parameters[:email] == '1'
      @range = ::Filters::DateRange.new(date_parameters)
      @range.validate
      errors = @range.errors.messages.map { |k, v| "#{k}: #{v.join(', ')}".humanize }

      @project_ids = params[:project]&.keys&.map(&:to_i) || []
      @project_ids = project_scope.where(id: @project_ids).pluck(:id) # viewability allowlist

      @project_group_ids = params[:project_group]&.keys&.map(&:to_i) || []
      @project_group_ids = project_group_scope.where(id: @project_group_ids).pluck(:id) # viewability allowlist

      errors << 'At least one project or project group must be selected' if @project_ids.empty? && @project_group_ids.empty?

      if errors.any?
        flash[:error] = errors.join('<br />'.html_safe)
      elsif @generate
        generate_for_projects(@project_ids, @email, @range, current_user)
        generate_for_project_groups(@project_group_ids, @email, @range, current_user)
      elsif @email
        email_to_projects(@project_ids, current_user)
        email_to_project_groups(@project_group_ids, current_user)
      end

      render action: :index
    end

    def edit
    end

    def update
      @report.update!(scorecard_params)
      render :show
    end

    private def generate_for_projects(ids, _send_email, range, user)
      ids.each do |id|
        reports_scope.create(project_id: id, user_id: user.id, start_date: range.first, end_date: range.last)
        # TODO: deferred generator
      end
    end

    private def generate_for_project_groups(ids, _send_email, range, user)
      ids.each do |id|
        reports_scope.create(project_group_id: id, user_id: user.id, start_date: range.first, end_date: range.last)
        # TODO: deferred generator
      end
    end

    private def email_to_projects(ids, user)
      ids.each do |id|
        @current_reports[id]&.send_email(user)
      end
    end

    private def email_to_project_groups(ids, user)
      ids.each do |id|
        @current_group_reports[id]&.send_email(user)
      end
    end

    private def create_parameters
      params.require(:scorecard).
        permit(
          :generate,
          :email,
        )
    end

    private def date_parameters
      params.require(:scorecard).
        permit(
          :start,
          :end,
        )
    end

    private def scorecard_params
      parameter_names = []
      @report.controlled_parameters.each do |name|
        parameter_names << name unless @report.locked?(name, current_user)
      end
      params.require(:project_scorecard_report).permit(*parameter_names)
    end

    private def project_scope
      GrdaWarehouse::Hud::Project.viewable_by current_user
    end

    private def project_group_scope
      GrdaWarehouse::ProjectGroup.viewable_by current_user
    end

    private def reports_scope
      ProjectScorecard::Report
    end

    private def set_projects
      @projects = project_scope.joins(:organization, :data_source).
        order(p_t[:data_source_id].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc).
        preload(:contacts, :data_source, organization: :contacts).
        group_by { |m| [m.data_source.short_name, m.organization] }
    end

    private def set_project_groups
      @project_groups = project_group_scope.includes(:projects).
        order(name: :asc).
        preload(:contacts, projects: [organization: :contacts])
    end

    private def set_report
      @report = reports_scope.find(params[:id].to_i)
    end

    private def set_current_reports
      @current_reports = reports_scope.
        where.not(project_id: nil).
        order(id: :asc).
        index_by(&:project_id)
      @current_group_reports = reports_scope.
        where.not(project_group_id: nil).
        order(id: :asc).
        index_by(&:project_id)
    end
  end
end
