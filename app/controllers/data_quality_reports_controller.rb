class DataQualityReportsController < ApplicationController
  include PjaxModalController
  # Authorize by either access to projects OR access by token
  skip_before_action :authenticate_user!
  before_action :require_valid_token_or_project_access!
  before_action :set_report, only: [:show, :answers, :support]
  before_action :set_project, only: [:show, :support]

  def show
    @utilization_grades = utilization_grade_scope.
      order(percentage_over_low: :asc)

    @missing_grades = missing_grade_scope.
      order(percentage_low: :asc)

    # The view is versioned using the model name
    render @report.model_name.element.to_sym
  end

  def index
    @project = project_source.find(params[:project_id].to_i)
    @reports = @project.data_quality_reports.order(started_at: :desc)
  end

  def answers
    @key = params[:key].to_s
    @data = @report.report&.[](@key)
    if @key.blank? || @data.blank?
      render json: @report.report
    else
      respond_to do |format|
        format.html do
          render json: @data
        end
        format.js do
          render json: @data
        end
      end
    end
  end

  def support
    @key = params[:key].to_s
    if @key.blank?
      render json: @report.support
    else
      support = @report.support
      @data = support[@key].with_indifferent_access
      respond_to do |format|
        format.xlsx do
          render xlsx: :index, filename: "support-#{@key}.xlsx"
        end
        format.html {}
        format.js {}
      end
    end
  end

  def report_scope
    GrdaWarehouse::WarehouseReports::Project::DataQuality::Base
  end

  def project_source
    GrdaWarehouse::Hud::Project.viewable_by current_user
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
      require_can_view_client_level_details!
      return
    end
    raise ActionController::RoutingError.new('Not Found')
  end

  def missing_grade_scope
    missing_grade_source.all
  end

  def missing_grade_source
    GrdaWarehouse::Grades::Missing
  end

  def utilization_grade_scope
    utilization_grade_source.all
  end

  def utilization_grade_source
    GrdaWarehouse::Grades::Utilization
  end

  def require_can_view_client_level_details!
    return true if current_user&.can_view_projects? || current_user&.can_view_project_data_quality_client_details?
    not_authorized!
  end
end