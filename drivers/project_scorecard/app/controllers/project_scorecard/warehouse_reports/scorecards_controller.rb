###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard::WarehouseReports
  class ScorecardsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_projects, :set_current_reports
    before_action :set_report, only: [:show, :edit, :update]

    def index
      start_date = Date.current.prev_month.beginning_of_month
      end_date = Date.current.prev_month.end_of_month

      @range = ::Filters::FilterBase.new(start: start_date, end: end_date)
    end

    def for_project
      project = project_scope.find(params[:project_id].to_i)
      @name = project.name
      @reports = reports_scope.where(project_id: project.id)
      render :report_list
    end

    def create
      @generate = create_params[:generate] == '1'
      @email = create_params[:email] == '1'

      @range = ::Filters::FilterBase.new
      @range.set_from_params(filter_params)
      errors = @range.errors.messages.map { |k, v| "#{k}: #{v.join(', ')}".humanize }

      @project_ids = params[:project]&.keys&.map(&:to_i) || []
      @project_ids = project_scope.where(id: @project_ids).pluck(:id) # viewability allowlist

      errors << 'At least one project must be selected' if @project_ids.empty?

      if errors.any?
        flash[:error] = errors.join('<br />'.html_safe)
      elsif @generate
        generate_for_projects(@project_ids, @email, @range, current_user)
      elsif @email
        email_to_projects(@project_ids)
      end

      render action: :index
    end

    def edit
    end

    def update
      @report.update!(scorecard_params)
      render :show
    end

    private def generate_for_projects(ids, send_email, range, user)
      ids.each do |id|
        report = reports_scope.create(project_id: id, user_id: user.id, start_date: range.first, end_date: range.last)
        ProjectScorecard::PopulateScorecard.perform_later(report.id, send_email, user.id)
      end
    end

    private def email_to_projects(ids)
      ids.each do |id|
        @current_reports[id]&.send_email
      end
    end

    private def create_params
      params.require(:scorecard).
        permit(
          :generate,
          :email,
        )
    end

    private def filter_params
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

    private def reports_scope
      ProjectScorecard::Report
    end

    private def set_projects
      base_scope = project_scope.joins(:organization, :data_source).
        order(p_t[:data_source_id].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc).
        preload(:contacts, :data_source, organization: :contacts)
      @projects = base_scope.ph.or(base_scope.rrh).
        group_by { |m| [m.data_source.short_name, m.organization] }
    end

    private def set_report
      @report = reports_scope.find(params[:id].to_i)
    end

    private def set_current_reports
      @current_reports = reports_scope.
        where.not(project_id: nil).
        order(id: :asc).
        index_by(&:project_id)
    end
  end
end
