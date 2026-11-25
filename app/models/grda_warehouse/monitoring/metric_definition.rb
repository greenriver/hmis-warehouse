###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/metric-tracking.md
module GrdaWarehouse::Monitoring
  class MetricDefinition < GrdaWarehouseBase
    include ArelHelper
    VALID_CATEGORIES = ['client_services', 'household_calculations', 'csv_import'].freeze

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
          active: true,
        )
        metric.save!
      end
    end

    # Get chart data showing threshold crossings over time
    # Returns array of [date_string, count] for days where entities crossed threshold
    # Counts per initial_observation_date, using the same crossing rules as threshold_crossings_for_date
    # @param entity_id [Integer, nil] optional - when set (e.g. for csv_import), scope to this entity only
    def threshold_crossing_data(days_back:, entity_id: nil)
      where_sql = 'current_snapshots.initial_observation_date BETWEEN ? AND ?'
      binds = [days_back.days.ago.to_date, Date.current]
      if entity_id.present?
        where_sql += ' AND current_snapshots.entity_id = ?'
        binds << entity_id
      end

      rows = select_crossing_rows(
        'current_snapshots.initial_observation_date AS observed_on, COUNT(*) AS crossing_count',
        where_sql,
        binds,
        'GROUP BY current_snapshots.initial_observation_date',
      )
      rows.map { |row| [row['observed_on'], row['crossing_count']] }.sort_by(&:first).map { |date, count| [date.to_date.to_s, count] }
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
    # Finds each snapshot's immediate previous snapshot with a lateral join, so only 2 records per entity are read
    def threshold_crossings_for_date(calculation_date, entity_ids:)
      return [] if entity_ids.empty?

      entity_ids_placeholder = entity_ids.map { '?' }.join(',')
      rows = select_crossing_rows(
        'current_snapshots.entity_id, current_snapshots.initial_value AS current_value, previous_snapshots.current_value AS previous_value',
        "current_snapshots.entity_id IN (#{entity_ids_placeholder}) AND current_snapshots.initial_observation_date = ?",
        [*entity_ids, calculation_date],
      )

      rows.map do |row|
        {
          entity_id: row['entity_id'],
          current_value: row['current_value'],
          previous_value: row['previous_value'],
        }
      end
    end

    private

    # The single definition of a threshold crossing, shared by the chart and the crossings list:
    # a snapshot that has a previous snapshot and, when the calculator requires it, a changed value.
    # Callers supply the select list, extra conditions (with bound values) and an optional trailing clause.
    def select_crossing_rows(select_sql, where_sql, where_binds, trailing_sql = '')
      value_change_condition = if calculator_class.constantize.crossing_requires_value_change?
        'AND current_snapshots.initial_value IS DISTINCT FROM previous_snapshots.current_value'
      else
        ''
      end
      sql = <<-SQL.squish
        SELECT #{select_sql}
        FROM metric_snapshots AS current_snapshots
        LEFT JOIN LATERAL (
          SELECT current_value
          FROM metric_snapshots AS prev
          WHERE prev.entity_type = current_snapshots.entity_type
            AND prev.metric_definition_id = current_snapshots.metric_definition_id
            AND prev.entity_id = current_snapshots.entity_id
            AND prev.initial_observation_date <= current_snapshots.initial_observation_date
            AND prev.id < current_snapshots.id
          ORDER BY prev.initial_observation_date DESC, prev.id DESC
          LIMIT 1
        ) AS previous_snapshots ON true
        WHERE current_snapshots.metric_definition_id = ?
          AND #{where_sql}
          AND previous_snapshots.current_value IS NOT NULL
          #{value_change_condition}
        #{trailing_sql}
      SQL

      self.class.connection.select_all(
        ActiveRecord::Base.sanitize_sql_array([sql, id, *where_binds]),
      ).to_a
    end
  end
end
