###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DataQualityReportsController < ApplicationController
  include AjaxModalRails::Controller
  skip_before_action :authenticate_user!, only: [:show, :answers]
  before_action :require_valid_token_or_report_access!, except: [:index]
  before_action :require_valid_token_or_project_access!

  before_action :set_project
  before_action :set_report, except: [:index]
  before_action :set_support_path, only: [:show]
  before_action :set_report_keys, only: [:show]

  def show
    @modal_size = :xl
    @utilization_grades = utilization_grade_scope.
      order(percentage_over_low: :asc)

    @missing_grades = missing_grade_scope.
      order(percentage_low: :asc)

    # The view is versioned using the model name
    render @report.model_name.element.to_sym
  end

  def index
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
    if params[:individual].present?
      @data = @report.support_for(support_params)
      @details_title = @data[:title] || 'Supporting Data'
      @method = params[:method]
      respond_to do |format|
        format.xlsx do
          render support_render_path, filename: "support-#{@method}.xlsx"
        end
        format.html do
          set_client_path
          # The view is versioned using the model name
          layout = if request.xhr?
            'ajax_modal_rails/content'
          else
            'application'
          end
          render support_render_path, layout: layout
        end
        format.js {}
      end
    else
      legacy_support
    end
  end

  def describe_computations
    path = "app/views/data_quality_reports/#{@report.model_name.element}/project/README.md"
    description = File.read(path)
    markdown = Redcarpet::Markdown.new(::TranslatedHtml)
    markdown.render(description)
  end
  helper_method :describe_computations

  def set_client_path
    @client_path = [:destination, :window, :source_client]
    @client_path = [:destination, :source_client] if can_view_clients?
  end

  def support_render_path
    "data_quality_reports/#{@report.model_name.element}/project/support"
  end

  def set_report_keys
    @report_keys = {
      project_id: @project.id,
      id: @report.id,
      individual: true,
    }
    @report_keys[:notification_id] = notification_id if notification_id
  end

  def set_support_path
    @support_path = [:project, :data_quality_report]
    @support_path = [:notification] + @support_path if notification_id
    @support_path = [:support] + @support_path
  end

  def legacy_support
    @key = params[:key].to_s
    if @key.blank?
      render json: @report.support
    else
      support = @report.support
      @data = support[@key].with_indifferent_access
      respond_to do |format|
        format.xlsx do
          render xlsx: 'index', filename: "support-#{@key}.xlsx"
        end
        format.html do
          render layout: 'ajax_modal_rails/content' if params[:layout].present? && params[:layout] == 'false'
        end
        format.js {}
      end
    end
  end

  def support_params
    params.permit(
      :selected_project_group_id,
      :selected_project_id,
      :method,
      :title,
      :layout,
      :column,
      :metric,
    )
  end

  def report_scope
    GrdaWarehouse::WarehouseReports::Project::DataQuality::Base
  end

  def project_scope
    project_source.viewable_by current_user
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  def set_report
    @report = report_scope.where(project_id: params[:project_id].to_i).find(params[:id].to_i)
  end

  def set_project
    @project = project_source.find(params[:project_id].to_i)
  end

  def notification_id
    params[:notification_id]
  end
  helper_method :notification_id

  def require_valid_token_or_report_access!
    if notification_id.present?
      token = GrdaWarehouse::ReportToken.find_by_token(notification_id)
      raise ActionController::RoutingError, 'Not Found' if token.blank?
      return true if token.valid?
    else
      set_report
      report_viewable = GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/project/data_quality').viewable_by(current_user).exists?
      return true if report_viewable

      not_authorized!
      return
    end
    raise ActionController::RoutingError, 'Not Found'
  end

  def require_valid_token_or_project_access!
    if notification_id.present?
      token = GrdaWarehouse::ReportToken.find_by_token(notification_id)
      raise ActionController::RoutingError, 'Not Found' if token.blank?
      return true if token.valid?
    else
      set_project
      project_viewable = project_scope.where(id: @project.id).exists?
      return true if project_viewable

      not_authorized!
      return
    end
    raise ActionController::RoutingError, 'Not Found'
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
end
