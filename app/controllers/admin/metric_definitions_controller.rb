###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class MetricDefinitionsController < ApplicationController
    before_action :require_can_edit_warehouse_alerts!
    before_action :load_metric_definition, only: [:show, :edit, :update]

    def index
      # Ensure definitions are up-to-date
      GrdaWarehouse::Monitoring::MetricDefinition.maintain!
      # Ensure alert definitions are seeded
      GrdaWarehouse::AlertDefinition.seed_initial_definitions

      @metric_definitions = metric_definition_scope.
        order(:category, :name)
    end

    def show
      # Get threshold crossing data for the last 90 days
      @chart_data = @metric_definition.threshold_crossing_data(days_back: 90)
      @entity_label = @metric_definition.entity_label
      @per_page_js = ['metric_threshold_chart']
    end

    def edit
    end

    def update
      if @metric_definition.update(metric_definition_params)
        redirect_to(
          admin_metric_definition_path(@metric_definition),
          notice: 'Metric definition updated',
        )
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    private

    def load_metric_definition
      @metric_definition = metric_definition_scope.find(params[:id])
    end

    def metric_definition_scope
      GrdaWarehouse::Monitoring::MetricDefinition.all
    end

    def metric_definition_params
      params.require(:grda_warehouse_monitoring_metric_definition).permit(
        :display_name,
        :description,
        :count_change_threshold,
        :percent_change_threshold,
        :active,
      )
    end
  end
end
