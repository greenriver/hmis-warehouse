class DataQualityReportsProjectGroupController < ApplicationController
  include PjaxModalController
  # Autorize by either access to projects OR access by token
  skip_before_action :authenticate_user!
  before_action :require_valid_token_or_project_access!
  before_action :set_report, only: [:show, :support]
  before_action :set_project_group, only: [:show, :support]

  def show

  end

  def support
    raise 'Key required' if params[:key].blank?
    @key = params[:key].to_s
    support = @report.support
    @data = support[@key].with_indifferent_access
    respond_to do |format|
      format.xlsx do
        render xlsx: :index, filename: "support-#{@key}.xlsx"
      end
      format.html {}
    end
  end

  def index
    @project_group = project_group_source.find(params[:project_group_id].to_i)
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def report_scope
    GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionOne
  end

  def project_group_source
    GrdaWarehouse::ProjectGroup
  end

  def set_report
    @report = report_scope.where(
      project_group_id: params[:project_group_id].to_i
    ).find(params[:id].to_i)
  end

  def set_project_group
    @project_group = @report.project_group
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