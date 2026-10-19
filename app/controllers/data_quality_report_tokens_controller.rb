###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Sends old emailed report links to the report page once the user has signed in.
class DataQualityReportTokensController < ApplicationControllerV2
  before_action :set_report
  authorize_with { current_user.policy_for(@report).can_view? }

  def show
    if @report.project_id
      redirect_to project_data_quality_report_path(project_id: @report.project_id, id: @report.id)
    else
      redirect_to project_group_data_quality_report_path(project_group_id: @report.project_group_id, id: @report.id)
    end
  end

  private def set_report
    @report = GrdaWarehouse::ReportToken.active.find_by!(token: params[:token]).report
    raise ActiveRecord::RecordNotFound unless @report
  end
end
