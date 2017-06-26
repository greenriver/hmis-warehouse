class DataQualityReportsController < ApplicationController
  include PjaxModalController
  # Autorize by either access to projects OR access by token
  skip_before_action :authenticate_user!
  before_action :require_valid_token_or_project_access!
  before_action :set_report, only: [:show, :support]
  before_action :set_project, only: [:show, :support]

  def show

  end

  def index
    @project = project_source.find(params[:project_id].to_i)
    @reports = @project.data_quality_reports.order(started_at: :desc)
  end

  def support
    raise 'Key required' if params[:key].blank?
    key = params[:key].to_s
    support = @report.support
    @data = support[key].with_indifferent_access
  end

  def report_scope
    GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionOne
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  def set_report
    @report = report_scope.where(project_id: params[:project_id].to_i).find(params[:id].to_i)
  end

  def set_project
    @project = @report.project
  end

  def require_valid_token_or_project_access!
    if params[:notification_id].present?
      token = GrdaWarehouse::ReportToken.find_by_token(params[:notification_id])
      raise ActionController::RoutingError.new('Not Found') if token.blank?
      return true if token.valid?
    else
      return require_can_view_projects!
    end
    raise ActionController::RoutingError.new('Not Found')
  end
end