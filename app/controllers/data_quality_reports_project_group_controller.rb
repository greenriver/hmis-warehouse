###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DataQualityReportsProjectGroupController < DataQualityReportsController
  include AjaxModalRails::Controller
  skip_before_action :set_project
  before_action :set_project_group

  def index
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def set_report_keys
    @report_keys = {
      project_group_id: @project_group.id,
      id: @report.id,
      individual: true,
    }
  end

  def set_support_path
    @support_path = [:project_group, :data_quality_report]
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

  def subject_viewable?
    project_group_scope.where(id: params[:project_group_id].to_i).exists?
  end
end
