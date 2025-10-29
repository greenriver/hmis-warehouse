###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring::Tasks
  class MetricSnapshotCollector
    BATCH_SIZE = 5_000

    def self.run_daily_collection(
      entity_type:,
      calculation_date: Date.current,
      entity_ids: nil,
      metric_names: nil
    )
      new(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: entity_ids,
        metric_names: metric_names,
      ).run
    end

    def initialize(entity_type:, calculation_date:, entity_ids: nil, metric_names: nil)
      @entity_type = entity_type
      @calculation_date = calculation_date
      @entity_ids = entity_ids
      @metric_names = metric_names
      @run_stats = {
        entities_evaluated: 0,
        metrics_calculated: 0,
        snapshots_created: 0,
        snapshots_updated: 0,
        errors: 0,
      }
    end

    def run
      # Ensure metric definitions are up-to-date before collection
      # Uses find_or_create_by! so this is idempotent and preserves user changes
      GrdaWarehouse::Monitoring::MetricDefinition.maintain!

      run_record = create_run_record

      metrics = load_metrics
      entities = load_entities

      Rails.logger.info "Collecting #{metrics.count} metrics for #{entities.count} #{@entity_type} records"

      entities.in_groups_of(BATCH_SIZE, false) do |entity_batch|
        collect_batch(entity_batch, metrics)
      end

      cleanup_old_snapshots
      complete_run_record(run_record, 'completed')

      # Trigger alert notifications for threshold crossings
      NotifyMetricThresholdCrossingsJob.perform_later(@calculation_date)
    end

    private

    def create_run_record
      GrdaWarehouse::Monitoring::MetricCalculationRun.find_or_create_by!(
        entity_type: @entity_type,
        calculation_date: @calculation_date,
      ) do |run|
        run.started_at = Time.current
        run.status = 'running'
      end
    end

    def complete_run_record(run_record, status, error_message = nil)
      run_record.update!(
        completed_at: Time.current,
        status: status,
        error_message: error_message,
        entities_evaluated_count: @run_stats[:entities_evaluated],
        metrics_calculated_count: @run_stats[:metrics_calculated],
        snapshots_created_count: @run_stats[:snapshots_created],
        snapshots_updated_count: @run_stats[:snapshots_updated],
        calculation_errors_count: @run_stats[:errors],
      )
    end

    def load_metrics
      scope = GrdaWarehouse::Monitoring::MetricDefinition.
        active.
        for_entity_type(@entity_type)

      scope = scope.where(name: @metric_names) if @metric_names.present?

      scope.to_a
    end

    def load_entities
      entity_class = @entity_type.constantize

      if @entity_ids.present?
        entity_class.where(id: @entity_ids)
      else
        get_active_entities(entity_class)
      end
    end

    def get_active_entities(entity_class)
      case @entity_type
      when 'GrdaWarehouse::Hud::Client'
        # Only process clients with warehouse_clients_processed records
        entity_class.
          destination.
          joins(:processed_service_history).
          distinct
      else
        entity_class.all
      end
    end

    def collect_batch(entities, metrics)
      @run_stats[:entities_evaluated] += entities.count

      # Load current snapshots for this batch
      current_snapshots = load_current_snapshots_for_batch(entities, metrics)

      snapshots_to_create = []
      snapshots_to_update = []

      metrics.each do |metric|
        @run_stats[:metrics_calculated] += entities.count

        begin
          process_metric_for_batch(
            entities,
            metric,
            current_snapshots,
            snapshots_to_create,
            snapshots_to_update,
          )
        rescue StandardError => e
          Rails.logger.error "Failed to calculate #{metric.name} for batch: #{e.message}"
          @run_stats[:errors] += entities.count
        end
      end

      # Bulk create and update
      import_snapshots(snapshots_to_create)
      update_snapshots(snapshots_to_update)
    end

    def load_current_snapshots_for_batch(entities, metrics)
      entity_ids = entities.map(&:id)
      metric_ids = metrics.map(&:id)

      # Find most recent snapshot for each entity/metric
      GrdaWarehouse::Monitoring::MetricSnapshot.
        where(entity_type: @entity_type, entity_id: entity_ids).
        where(metric_definition_id: metric_ids).
        where(current_observation_date: @calculation_date - 1.day..).
        group_by { |s| [s.entity_id, s.metric_definition_id] }.
        transform_values(&:first)
    end

    def process_metric_for_batch(entities, metric, current_snapshots, snapshots_to_create, snapshots_to_update)
      calculator_class = metric.calculator_class.constantize

      # Use batch calculation
      calculated_values = calculator_class.calculate_batch(entities, @calculation_date)

      calculated_values.each do |entity_id, calculated_value|
        # Skip nil values (no data available)
        next if calculated_value.nil?

        current_snapshot = current_snapshots[[entity_id, metric.id]]

        if should_create_new_snapshot?(metric, current_snapshot, calculated_value)
          # Significant change detected - create new snapshot
          entity = entities.find { |e| e.id == entity_id }
          snapshot = build_new_snapshot(
            entity,
            metric,
            calculated_value,
            calculator_class.new(entity, @calculation_date).version,
          )
          snapshots_to_create << snapshot
          @run_stats[:snapshots_created] += 1
        elsif current_snapshot
          # Value within threshold - update current_value and extend current_observation_date
          # Store original date before modifying for bulk update
          current_snapshot.instance_variable_set(:@original_current_observation_date, current_snapshot.current_observation_date)
          current_snapshot.current_value = calculated_value
          current_snapshot.current_observation_date = @calculation_date
          snapshots_to_update << current_snapshot
          @run_stats[:snapshots_updated] += 1
        else
          # First time calculating - create initial snapshot
          entity = entities.find { |e| e.id == entity_id }
          snapshot = build_new_snapshot(
            entity,
            metric,
            calculated_value,
            calculator_class.new(entity, @calculation_date).version,
          )
          snapshots_to_create << snapshot
          @run_stats[:snapshots_created] += 1
        end
      end
    end

    def should_create_new_snapshot?(metric, current_snapshot, calculated_value)
      # No current snapshot = first time, create new
      return false unless current_snapshot

      # Compare calculated value to initial_value (baseline)
      baseline_value = current_snapshot.initial_value

      # Handle nil values
      return true if calculated_value.nil? != baseline_value.nil?
      return false if calculated_value.nil? && baseline_value.nil?

      # If no thresholds specified, create new snapshot on any change
      count_threshold = metric.count_change_threshold
      percent_threshold = metric.percent_change_threshold
      return calculated_value != baseline_value if count_threshold.nil? && percent_threshold.nil?

      # Calculate change from baseline
      change = (calculated_value - baseline_value).abs

      # Check thresholds
      count_met = false
      percent_met = false

      # Check count threshold
      count_met = change >= count_threshold if count_threshold

      # Check percent threshold
      if percent_threshold && baseline_value != 0
        percent_change = (change.to_f / baseline_value.abs * 100)
        percent_met = percent_change >= percent_threshold
      end

      # Both thresholds must be met if both are specified
      if count_threshold && percent_threshold
        return count_met && percent_met
      elsif count_threshold
        return count_met
      elsif percent_threshold
        return percent_met
      end

      # No thresholds crossed
      false
    end

    def build_new_snapshot(entity, metric, value, calculation_version)
      GrdaWarehouse::Monitoring::MetricSnapshot.new(
        entity: entity,
        metric_definition: metric,
        initial_observation_date: @calculation_date,
        current_observation_date: @calculation_date,
        initial_value: value,
        current_value: value,
        calculation_version: calculation_version,
      )
    end

    def import_snapshots(snapshots)
      return if snapshots.empty?

      # Specify columns explicitly to exclude id (let database auto-generate it)
      columns = [
        :entity_type,
        :entity_id,
        :metric_definition_id,
        :initial_observation_date,
        :current_observation_date,
        :initial_value,
        :current_value,
        :calculation_version,
        :created_at,
        :updated_at,
      ]

      GrdaWarehouse::Monitoring::MetricSnapshot.import(
        columns,
        snapshots.map do |s|
          [
            s.entity_type,
            s.entity_id,
            s.metric_definition_id,
            s.initial_observation_date,
            s.current_observation_date,
            s.initial_value,
            s.current_value,
            s.calculation_version,
            s.created_at,
            s.updated_at,
          ]
        end,
        on_duplicate_key_update: {
          conflict_target: [
            :entity_type,
            :entity_id,
            :metric_definition_id,
            :initial_observation_date,
            :current_observation_date,
          ],
          columns: [
            :initial_value,
            :current_value,
            :calculation_version,
            :updated_at,
          ],
        },
      )
    end

    def update_snapshots(snapshots)
      return if snapshots.empty?

      # Build bulk UPDATE using natural composite key
      # We use the natural key (entity_type, entity_id, metric_definition_id, initial_observation_date)
      # along with the OLD current_observation_date to match existing records
      conn = GrdaWarehouseBase.connection
      updated_at = Time.current.strftime('%Y-%m-%d %H:%M:%S')

      # Create VALUES rows for bulk update using natural key
      # Note: We use the original current_observation_date to match the existing row
      values_list = snapshots.map do |s|
        # Get the original current_observation_date that we stored before modification
        original_date = s.instance_variable_get(:@original_current_observation_date)
        original_date_str = original_date.strftime('%Y-%m-%d')

        # Use proper SQL escaping for all values
        entity_type = conn.quote(s.entity_type)
        entity_id = s.entity_id.to_i
        metric_definition_id = s.metric_definition_id.to_i
        initial_observation_date = conn.quote(s.initial_observation_date.strftime('%Y-%m-%d'))
        old_current_observation_date = conn.quote(original_date_str)
        new_current_value = s.current_value.to_i
        new_current_observation_date = conn.quote(s.current_observation_date.strftime('%Y-%m-%d'))

        "(#{entity_type}, #{entity_id}, #{metric_definition_id}, " \
          "#{initial_observation_date}, #{old_current_observation_date}, " \
          "#{new_current_value}, #{new_current_observation_date})"
      end.join(',')

      sql = <<~SQL
        UPDATE #{GrdaWarehouse::Monitoring::MetricSnapshot.quoted_table_name}
        SET
          current_value = v.new_current_value::integer,
          current_observation_date = v.new_current_observation_date::date,
          updated_at = #{conn.quote(updated_at)}
        FROM (VALUES #{values_list}) AS v(
          entity_type, entity_id, metric_definition_id, initial_observation_date,
          old_current_observation_date, new_current_value, new_current_observation_date
        )
        WHERE #{GrdaWarehouse::Monitoring::MetricSnapshot.quoted_table_name}.entity_type = v.entity_type
          AND #{GrdaWarehouse::Monitoring::MetricSnapshot.quoted_table_name}.entity_id = v.entity_id
          AND #{GrdaWarehouse::Monitoring::MetricSnapshot.quoted_table_name}.metric_definition_id = v.metric_definition_id
          AND #{GrdaWarehouse::Monitoring::MetricSnapshot.quoted_table_name}.initial_observation_date = v.initial_observation_date::date
          AND #{GrdaWarehouse::Monitoring::MetricSnapshot.quoted_table_name}.current_observation_date = v.old_current_observation_date::date
      SQL

      conn.execute(sql)
    end

    def cleanup_old_snapshots
      cutoff_date = @calculation_date - 3.years

      deleted_count = GrdaWarehouse::Monitoring::MetricSnapshot.
        where(current_observation_date: ...cutoff_date).
        delete_all

      Rails.logger.info "Cleaned up #{deleted_count} snapshots older than #{cutoff_date}" if deleted_count.positive?
    end
  end
end
