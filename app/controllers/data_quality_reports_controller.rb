###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DataQualityReportsController < ApplicationControllerV2
  include AjaxModalRails::Controller
  include WarehouseReportAuthorizationV2
  include WarehouseReports::PiiDetailRows

  before_action :set_project
  before_action :set_report, except: [:index]
  authorize_with(only: :index) { subject_viewable? || viewable_subject_reports.exists? }
  authorize_with(except: :index) { report_policy.can_view? }
  authorize_with(only: :support) { can_view_dq_support? }
  before_action :set_support_path, only: [:show]
  before_action :set_report_keys, only: [:show]

  def related_report
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: report_scope.url)
  end

  helper_method def report_policy
    current_user.policy_for(@report)
  end

  helper_method def can_view_dq_support?
    report_policy.can_view_client_details?
  end

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
    @reports = viewable_subject_reports.order(started_at: :desc)
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

      if !current_user.can_view_confidential_project_names? && @data[:headers].include?('Project ID')
        project_id_col = @data[:headers].find_index('Project ID')
        project_name_col = @data[:headers].find_index('Project')
        @data[:counts].each_with_index do |row, i|
          @data[:counts][i][project_name_col] = GrdaWarehouse::Hud::Project.confidential_project_name if confidential_project_ids.include?(row[project_id_col])
        end
      end

      @details_title = @data[:title] || 'Supporting Data'
      @method = params[:method]
      current_user.policy_context.preload_client_dependencies(@data[:counts].map { |row| row[0] })
      respond_to do |format|
        format.xlsx do
          @data[:counts] = @data[:counts].map { |row| redact_pii_in_row(row, headers: @data[:headers], user: current_user, mode: :download) }
          render support_render_path, filename: "support-#{@method}.xlsx"
        end
        format.html do
          @data[:counts] = @data[:counts].map { |row| redact_pii_in_row(row, headers: @data[:headers], user: current_user, mode: :browse) }
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
    @client_path = [:destination, :source_client] if current_user.can_view_clients?
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
  end

  def set_support_path
    @support_path = [:project, :data_quality_report]
    @support_path = [:support] + @support_path
  end

  def legacy_support
    @key = params[:key].to_s
    if @key.blank?
      render json: @report.support
    else
      support = @report.support
      @data = support[@key].with_indifferent_access
      current_user.policy_context.preload_client_dependencies(@data[:counts].map { |row| row[0] })
      respond_to do |format|
        format.xlsx do
          @data[:counts] = @data[:counts].map { |row| redact_pii_in_row(row, headers: @data[:headers], user: current_user, mode: :download) }
          render xlsx: 'index', filename: "support-#{@key}.xlsx"
        end
        format.html do
          @data[:counts] = @data[:counts].map { |row| redact_pii_in_row(row, headers: @data[:headers], user: current_user, mode: :browse) }
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

  def subject_viewable?
    project_scope.where(id: params[:project_id].to_i).exists?
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  def subject_reports
    report_scope.where(project_id: params[:project_id].to_i)
  end

  def viewable_subject_reports
    subject_reports.where(id: GrdaWarehouse::AuthPolicies::DataQualityReportPolicy.viewable_reports(current_user).select(:id))
  end

  def set_report
    @report = subject_reports.find(params[:id].to_i)
  end

  def set_project
    @project = project_source.find(params[:project_id].to_i)
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

  def confidential_project_ids
    projects = Rails.cache.fetch('confidential_project_ids', expires_in: 2.minutes) do
      GrdaWarehouse::Hud::Project.confidential.pluck(:id).to_set
    end
    projects
  end
end
