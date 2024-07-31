###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::WarehouseReports
  class StaticSpmsController < ApplicationController
    # include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    before_action :set_goal

    def new
      @spm = spm_source.new(goal: @goal)
    end

    def edit
      @spm = spm_source.find(params[:id].to_i)
    end

    def create
      @spm = spm_source.create!({ goal: @goal }.merge(spm_params.to_h))
      respond_with(@spm, location: edit_performance_measurement_warehouse_reports_goal_config_path(@goal))
    end

    def update
      @spm = spm_source.find(params[:id].to_i)
      @spm.update!(spm_params)
      respond_with(@goal, location: edit_performance_measurement_warehouse_reports_goal_config_path(@goal))
    end

    def destroy
      @spm = spm_source.find(params[:id].to_i)
      @spm.destroy
      respond_with(@goal, location: edit_performance_measurement_warehouse_reports_goal_config_path(@goal))
    end

    private def set_goal
      @goal = goal_source.find(params[:goal_config_id].to_i)
    end

    private def goal_source
      PerformanceMeasurement::Goal
    end

    private def spm_source
      PerformanceMeasurement::StaticSpm
    end

    def spm_params
      fields = [
        :report_start,
        :report_end,
      ]
      spm_source::KNOWN_SPM_METHODS.each do |_, _, method|
        fields << method
      end
      params.require(:spm).permit(*fields)
    end

    private def flash_interpolation_options
      { resource_name: 'Static SPM' }
    end
  end
end
