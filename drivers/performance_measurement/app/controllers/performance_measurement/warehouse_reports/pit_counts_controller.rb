###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::WarehouseReports
  class PitCountsController < ApplicationController
    # include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    before_action :set_goal

    def new
      @pit_count = pit_count_source.new(goal: @goal)
    end

    def create
      @pit_count = pit_count_source.create!({ goal: @goal }.merge(pit_count_params.to_h))
      respond_with(@pit_count, location: edit_performance_measurement_warehouse_reports_goal_config_path(@goal))
    end

    def destroy
      @pit_count = pit_count_source.find(params[:id].to_i)
      @pit_count.destroy
      respond_with(@goal, location: edit_performance_measurement_warehouse_reports_goal_config_path(@goal))
    end

    private def set_goal
      @goal = goal_source.find(params[:goal_config_id].to_i)
    end

    private def goal_source
      PerformanceMeasurement::Goal
    end

    private def pit_count_source
      PerformanceMeasurement::PitCount
    end

    def pit_count_params
      params.require(:pit_count).permit(
        :pit_date,
        :unsheltered,
        :sheltered,
      )
    end

    private def flash_interpolation_options
      { resource_name: 'PIT Count' }
    end
  end
end
