###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance::WarehouseReports
  class GoalConfigsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    before_action :set_goal, only: [:edit, :update, :destroy]

    def index
      goal_source.ensure_default
      @goals = goal_source.default_first
    end

    def edit
    end

    def create
      @goal = goal_source.create(coc_code: 'Un-Set')
      respond_with(@goal, location: edit_ce_performance_warehouse_reports_goal_config_path(@goal))
    end

    def update
      @goal.update(goal_params)
      respond_with(@goal, location: ce_performance_warehouse_reports_goal_configs_path)
    end

    def destroy
      @goal.destroy
      respond_with(@goal, location: ce_performance_warehouse_reports_goal_configs_path)
    end

    private def set_goal
      @goal = goal_source.find(params[:id].to_i)
    end

    private def goal_source
      CePerformance::Goal
    end

    def goal_params
      p = params.require(:goal).permit(
        :coc_code,
        :screening,
        :diversion,
        :time_in_ce,
        :time_to_referral,
        :time_to_housing,
        :time_on_list,
      )
      p[:coc_code] = :default if p[:coc_code].blank?
      p
    end

    private def flash_interpolation_options
      { resource_name: 'CE Performance Goal Configuration' }
    end
  end
end
