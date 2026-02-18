###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/metric-tracking.md
module GrdaWarehouse::Monitoring
  class MetricDefinition < GrdaWarehouseBase
    include ArelHelper
    VALID_CATEGORIES = ['client_services', 'household_calculations', 'csv_import'].freeze
    COLLECTION_HOUR = 2 # Hour of day (0-23) to run daily metric collection

    has_many :metric_snapshots,
             class_name: 'GrdaWarehouse::Monitoring::MetricSnapshot',
             dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :entity_type }
    validates :entity_type, presence: true
    validates :calculator_class, presence: true
    validates :category, inclusion: { in: VALID_CATEGORIES }, allow_nil: true

    scope :active, -> { where(active: true) }
    scope :for_entity_type, ->(type) { where(entity_type: type) }

    # Instantiate calculator for given entity
    def calculator_for(entity, calculation_date)
      calculator_class.constantize.new(
        entity,
        calculation_date,
      )
    end

    # Calculate and return value
    def calculate_value(entity, calculation_date)
      calculator_for(
        entity,
        calculation_date,
      ).calculate
    end

    # List of all available calculator classes
    def self.available_calculators
      [
        GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator,
        GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator,
        GrdaWarehouse::Monitoring::MetricCalculators::MaxHouseholdSizeCalculator,
      ]
    end

    # Attributes in metric_definition_attributes that are not database columns
    def self.non_database_attributes
      [:alert_code]
    end

    # Initialize default metric definitions
    # Called once via TaskQueue to populate the table
    # Uses advisory lock to prevent concurrent execution - returns immediately if lock is held
    def self.maintain!
      lock_name = 'metric_definition_maintain'
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0) do
        available_calculators.each do |calculator_class|
          attrs = calculator_class.metric_definition_attributes
          find_or_create_by!(
            name: attrs[:name],
            entity_type: attrs[:entity_type],
          ) do |metric|
            metric.assign_attributes(attrs.except(*non_database_attributes))
          end
        end
        maintain_csv_metrics!
      end
    end

    # Create metric definitions for each allowed CSV file (for per-CSV import monitoring)
    def self.maintain_csv_metrics!
      return unless defined?(GrdaWarehouse::ImportCsvMonitor)

      csv_files = GrdaWarehouse::ImportCsvMonitor.allowed_csv_files
      calculator_class = GrdaWarehouse::Monitoring::MetricCalculators::CsvRowCountMetricCalculator.name

      csv_files.each do |csv_file_name|
        metric_name = "csv_row_count_#{csv_file_name.gsub('.csv', '').parameterize.underscore}"
        metric = find_or_initialize_by(
          name: metric_name,
          entity_type: 'GrdaWarehouse::DataSource',
        )
        metric.assign_attributes(
          display_name: "#{csv_file_name} row count",
          description: "Row count for #{csv_file_name} from import summary",
          calculator_class: calculator_class,
          category: 'csv_import',
          subtype: csv_file_name,
          active: false,
        )
        metric.save!
      end
    end

    # Get chart data showing threshold crossings over time
    # Returns array of [date_string, count] for days where entities crossed threshold
    # Excludes initial observations (first snapshot for each entity/metric)
    def threshold_crossing_data(days_back:)
      start_date = days_back.days.ago.to_date
      end_date = Date.current

      snapshot_table = GrdaWarehouse::Monitoring::MetricSnapshot.arel_table

      # Find initial snapshot IDs (first snapshot for each entity/metric combination)
      initial_snapshot_ids = metric_snapshots.
        select(snapshot_table[:id].minimum).
        group(:entity_type, :entity_id, :metric_definition_id)

      # Get non-initial snapshots created in the date range
      # Group by creation date and count entities
      crossings = metric_snapshots.
        where(created_at: start_date.beginning_of_day..end_date.end_of_day).
        where.not(id: initial_snapshot_ids).
        group(Arel.sql('DATE(created_at)')).
        count

      # Convert to array of [date_string, count] sorted by date
      crossings.map { |date, count| [date.to_s, count] }.sort_by { |d| d[0] }
    end

    # Get human-readable entity label for chart axis
    def entity_label
      case entity_type
      when 'GrdaWarehouse::Hud::Client'
        'Client'
      when 'GrdaWarehouse::Hud::Project'
        'Project'
      when 'GrdaWarehouse::DataSource'
        'Data Source'
      when 'GrdaWarehouse::Hud::Organization'
        'Organization'
      else
        'Entity'
      end
    end

    # Get alert code from calculator
    # Returns nil if calculator doesn't specify an alert_code
    def alert_code
      attrs = calculator_class.constantize.metric_definition_attributes
      attrs[:alert_code]
    end

    # Get threshold crossings grouped by alert code for a given calculation date
    # Returns hash: { alert_code => { metric_display_name => { data: [...], total_count:, truncated: } } }
    # Only includes metrics that have an alert_code defined
    # Excludes initial observations (first snapshot for each entity/metric)
    # Limits to 50 clients per metric to prevent overwhelming emails
    # Uses optimized threshold_crossings_for_date internally
    def self.threshold_crossings_for_alerts(calculation_date, limit: 50)
      results = {}

      active.each do |metric|
        next unless metric.alert_code # Skip metrics without alert codes

        # Get all entity_ids that have crossings on this date
        entity_ids = metric.metric_snapshots.
          where(initial_observation_date: calculation_date).
          distinct.
          pluck(:entity_id)

        next if entity_ids.empty?

        # Use optimized method to get crossings
        crossings = metric.threshold_crossings_for_date(calculation_date, entity_ids: entity_ids)

        next if crossings.empty?

        # Initialize nested structure if needed
        results[metric.alert_code] ||= {}
        total_count = crossings.count
        truncated = total_count > limit

        results[metric.alert_code][metric.id] = {
          display_name: metric.display_name,
          data: crossings.first(limit),
          total_count: total_count,
          truncated: truncated,
        }
      end

      results
    end

    # Get threshold crossings for this metric on a specific date
    # Returns array of hashes with entity_id, current_value, previous_value
    # Excludes initial observations (first snapshot for each entity/metric)
    # Optimized to use window function to find previous snapshots - only loads 2 records per entity max
    def threshold_crossings_for_date(calculation_date, entity_ids:)
      return [] if entity_ids.empty?

      # Use a single query that finds current snapshots and their immediate previous snapshots
      # Uses lateral join to efficiently find only the previous snapshot per entity
      # This ensures we only load 2 records per entity at most (current + previous)
      entity_ids_placeholder = entity_ids.map { '?' }.join(',')
      sql = <<-SQL.squish
        SELECT
          current_snapshots.id,
          current_snapshots.entity_id,
          current_snapshots.initial_value AS current_value,
          previous_snapshots.current_value AS previous_value
        FROM metric_snapshots AS current_snapshots
        LEFT JOIN LATERAL (
          SELECT current_value
          FROM metric_snapshots AS prev
          WHERE prev.metric_definition_id = current_snapshots.metric_definition_id
            AND prev.entity_id = current_snapshots.entity_id
            AND prev.id < current_snapshots.id
          ORDER BY prev.id DESC
          LIMIT 1
        ) AS previous_snapshots ON true
        WHERE current_snapshots.metric_definition_id = ?
          AND current_snapshots.entity_id IN (#{entity_ids_placeholder})
          AND current_snapshots.initial_observation_date = ?
          AND previous_snapshots.current_value IS NOT NULL
      SQL

      results = self.class.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([sql, id, *entity_ids, calculation_date]),
      )

      crossings = []
      results.each do |row|
        crossings << {
          entity_id: row['entity_id'],
          current_value: row['current_value'],
          previous_value: row['previous_value'],
        }
      end

      crossings
    end
  end
end
