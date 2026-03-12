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
        where.not(category: 'csv_import').
        order(:category, :name)

      # Data sources with ImportCsvMonitors (for Import CSV Monitors section)
      @import_csv_data_sources = data_sources_with_import_csv_monitors if defined?(GrdaWarehouse::ImportCsvMonitor)
    end

    def show
      @entity_id_filter = params[:entity_id].presence&.to_i
      @chart_data = @metric_definition.threshold_crossing_data(
        days_back: 90,
        entity_id: @entity_id_filter,
      )
      @entity_label = @metric_definition.entity_label
      @per_page_js = ['metric_threshold_chart']

      # For csv_import metrics with entity_id, load the ImportCsvMonitor (per-data-source config)
      @import_csv_monitor = nil
      return unless @metric_definition.category == 'csv_import' && @metric_definition.subtype.present? && @entity_id_filter.present?

      @import_csv_monitor = GrdaWarehouse::ImportCsvMonitor.find_by(
        data_source_id: @entity_id_filter,
        csv_file_name: @metric_definition.subtype,
      )
    end

    def crossings_for_date
      calculation_date = if params[:date].blank?
        @metric_definition.metric_snapshots.order(id: :asc).last&.initial_observation_date || Date.current
      else
        Date.strptime(params[:date], '%Y-%m-%d')
      end

      # Get all entity IDs that crossed on this date
      snapshot_scope = @metric_definition.metric_snapshots.crossed_threshold_on_date(calculation_date)
      snapshot_scope = snapshot_scope.where(entity_id: params[:entity_id]) if params[:entity_id].present?
      entity_ids = snapshot_scope.distinct.pluck(:entity_id)

      # Fetch crossings for all entities in one optimized query
      crossings = @metric_definition.threshold_crossings_for_date(calculation_date, entity_ids: entity_ids)

      # Build client URLs based on entity type
      crossings_with_urls = crossings.map do |crossing|
        entity_url = case @metric_definition.entity_type
        when 'GrdaWarehouse::Hud::Client'
          client_path(crossing[:entity_id])
        when 'GrdaWarehouse::DataSource'
          data_source_path(crossing[:entity_id])
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

    def data_sources_with_import_csv_monitors
      GrdaWarehouse::DataSource.
        joins(:import_csv_monitors).
        distinct.
        preload(import_csv_monitors: :data_source).
        order(:name)
    end
  end
end
