###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DataQualityReportsProjectGroupController < DataQualityReportsController
  include AjaxModalRails::Controller
  # Authorize by either access to projects OR access by token
  skip_before_action :authenticate_user!, only: [:show, :answers]
  skip_before_action :set_project
  before_action :require_valid_token_or_project_access!
  before_action :set_report, only: [:show, :support, :answers]
  before_action :set_project_group, only: [:show, :support, :answers]
  before_action :set_support_path, only: [:show]
  before_action :set_report_keys, only: [:show]

  def index
    @project_group = project_group_source.find(params[:project_group_id].to_i)
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def set_report_keys
    @report_keys = {
      project_group_id: @project_group.id,
      id: @report.id,
      individual: true,
    }
    @report_keys[:notification_id] = notification_id if notification_id
  end

  def set_support_path
    @support_path = [:project_group, :data_quality_report]
    @support_path = [:notification] + @support_path if notification_id
    @support_path = [:support] + @support_path
  end

  def support_render_path
    "data_quality_reports/#{@report.model_name.element}/project_group/support"
  end

  def project_group_source
    GrdaWarehouse::ProjectGroup
  end

  def set_report
    @report = report_scope.where(project_group_id: params[:project_group_id].to_i).find(params[:id].to_i)
  end

  def set_project_group
    @project_group = project_group_source.find(params[:project_group_id].to_i)
  end

  def project_group_scope
    project_group_source.viewable_by current_user
  end

  def require_valid_token_or_project_access!
    if notification_id.present?
      token = GrdaWarehouse::ReportToken.find_by_token(notification_id)
      raise ActionController::RoutingError, 'Not Found' if token.blank?
      return true if token.valid?
    else
      set_project_group
      project_group_viewable = project_group_scope.where(id: @project_group.id).exists?
      return true if project_group_viewable

      not_authorized!
      return
    end
    raise ActionController::RoutingError, 'Not Found'
  end
end
