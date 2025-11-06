###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class MetricDefinitionsController < ApplicationController
    before_action :require_can_edit_warehouse_alerts!
    before_action :load_metric_definition, only: [:show, :edit, :update, :crossings_for_date]

    def index
      # Ensure definitions are up-to-date
      GrdaWarehouse::Monitoring::MetricDefinition.maintain!
      # Ensure alert definitions are seeded
      GrdaWarehouse::AlertDefinition.maintain!

      @metric_definitions = metric_definition_scope.
        order(:category, :name)
    end

    def show
      # Get threshold crossing data for the last 90 days
      @chart_data = @metric_definition.threshold_crossing_data(days_back: 90)
      @entity_label = @metric_definition.entity_label
      @per_page_js = ['metric_threshold_chart']
    end

    def crossings_for_date
      calculation_date = if params[:date].blank?
        @metric_definition.metric_snapshots.order(id: :asc).last&.initial_observation_date || Date.current
      else
        Date.strptime(params[:date], '%Y-%m-%d')
      end

      # Get all entity IDs that crossed on this date
      entity_ids = @metric_definition.metric_snapshots.
        crossed_threshold_on_date(calculation_date).
        distinct.
        pluck(:entity_id)

      # Fetch crossings for all entities in one optimized query
      crossings = @metric_definition.threshold_crossings_for_date(calculation_date, entity_ids: entity_ids)

      # Build client URLs based on entity type
      crossings_with_urls = crossings.map do |crossing|
        entity_url = case @metric_definition.entity_type
        when 'GrdaWarehouse::Hud::Client'
          client_path(crossing[:entity_id])
        end

        {
          entity_id: crossing[:entity_id],
          current_value: crossing[:current_value],
          previous_value: crossing[:previous_value],
          change: crossing[:current_value] - crossing[:previous_value],
          entity_url: entity_url,
        }
      end

      render json: {
        date: calculation_date.to_fs,
        crossings: crossings_with_urls,
      }
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
