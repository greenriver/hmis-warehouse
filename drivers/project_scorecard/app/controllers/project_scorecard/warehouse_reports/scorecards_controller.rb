###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard::WarehouseReports
  class ScorecardsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    # TODO: wjat are the access rules?
    before_action :set_projects, :set_current_reports
    before_action :set_report, only: [:show, :edit, :rewind, :complete, :update]

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

    def show
      report_id = { report_id: @report.id }
      @pdf_export = ProjectScorecard::DocumentExports::ScorecardExport.new(query_string: report_id.to_query)
    end

    def create
      @range = ::Filters::FilterBase.new
      @range.set_from_params(filter_params)
      errors = @range.errors.messages.map { |k, v| "#{k}: #{v.join(', ')}".humanize }

      @project_ids = params[:project]&.keys&.map(&:to_i) || []
      @project_ids = project_scope.where(id: @project_ids).pluck(:id) # viewability allowlist

      errors << 'At least one project must be selected' if @project_ids.empty?

      if errors.any?
        flash[:error] = errors.join('<br />'.html_safe)
        render action: :index
      else
        generate_for_projects(@project_ids, @range, current_user)
        flash[:info] = 'Reports queued for processing'
        redirect_to action: :index
      end
    end

    def edit
    end

    def rewind
      rewind_workflow
      redirect_to action: :show
    end

    def complete
      advance_workflow
      redirect_to action: :show
    end

    def update
      @report.update!(scorecard_params)
      advance_workflow if params[:commit] == workflow_action
      action = :edit
      action = :show if @report.status == 'completed'
      redirect_to action: action
    end

    def workflow_action
      case @report.status
      when 'pre-filled'
        'Save & Send to Contacts'
      when 'ready'
        'Save & Submit'
      when 'completed'
        nil
      end
    end
    helper_method :workflow_action

    private def rewind_workflow
      case @report.status
      when 'ready'
        @report.update!(status: 'pre-filled')
      when 'completed'
        @report.update!(
          completed_at: Time.current,
          status: 'ready',
        )
      end
    end

    private def advance_workflow
      case @report.status
      when 'pre-filled'
        @report.update!(status: 'ready')
      when 'ready'
        @report.update!(
          completed_at: Time.current,
          status: 'completed',
        )
      end
    end

    private def generate_for_projects(ids, range, user)
      ids.each do |id|
        report = reports_scope.create(project_id: id, user_id: user.id, start_date: range.first, end_date: range.last)
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: user.id,
          report_class: report.class.name,
          report_id: report.id,
        )
      end
    end

    private def email_to_projects(ids)
      ids.each do |id|
        @current_reports[id]&.send_email
      end
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

    private def organization_scope
      GrdaWarehouse::Hud::Organization.viewable_by current_user
    end

    private def project_scope
      GrdaWarehouse::Hud::Project.viewable_by current_user
    end

    private def reports_scope
      ProjectScorecard::Report
    end

    private def set_projects
      @organizations = organization_scope.order(OrganizationName: :asc).
        page(params[:page]).
        per(100)

      base_scope = project_scope.joins(:organization, :data_source).
        merge(organization_scope.where(id: @organizations.select(:id))).
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
