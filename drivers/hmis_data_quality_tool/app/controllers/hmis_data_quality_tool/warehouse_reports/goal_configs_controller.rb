###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool::WarehouseReports
  class GoalConfigsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    before_action :set_goal, only: [:edit, :update, :destroy]

    def index
      @report = ::HmisDataQualityTool::Report.new(user: current_user)
      goal_source.ensure_default
      @goals = goal_source.default_first
    end

    def edit
      @report = ::HmisDataQualityTool::Report.new(user: current_user)
    end

    def create
      @goal = goal_source.create(coc_code: 'Un-Set')
      respond_with(@goal, location: edit_hmis_data_quality_tool_warehouse_reports_goal_config_path(@goal))
    end

    def update
      @goal.update(goal_params)
      respond_with(@goal, location: hmis_data_quality_tool_warehouse_reports_goal_configs_path)
    end

    def destroy
      @goal.destroy
      respond_with(@goal, location: hmis_data_quality_tool_warehouse_reports_goal_configs_path)
    end

    private def set_goal
      @goal = goal_source.find(params[:id].to_i)
    end

    private def goal_source
      ::HmisDataQualityTool::Goal
    end

    def goal_params
      p = params.require(:goal).permit(goal_source.known_params)
      p[:coc_code] = 'Un-Set' if p[:coc_code].blank?
      p
    end

    private def flash_interpolation_options
      { resource_name: "#{_('HMIS Data Quality Tool')} Configuration" }
    end
  end
end
