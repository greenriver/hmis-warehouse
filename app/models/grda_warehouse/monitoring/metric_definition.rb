###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring
  class MetricDefinition < GrdaWarehouseBase
    include ArelHelper
    VALID_CATEGORIES = ['client_services', 'household_calculations'].freeze
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
    def self.maintain!
      available_calculators.each do |calculator_class|
        attrs = calculator_class.metric_definition_attributes
        find_or_create_by!(
          name: attrs[:name],
          entity_type: attrs[:entity_type],
        ) do |metric|
          metric.assign_attributes(attrs.except(*non_database_attributes))
        end
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
    def self.threshold_crossings_for_alerts(calculation_date, limit: 50)
      results = {}

      active.each do |metric|
        next unless metric.alert_code # Skip metrics without alert codes

        # Get all snapshots where the threshold crossing occurred on this date
        current_snapshots = metric.metric_snapshots.
          where(initial_observation_date: calculation_date).
          order(:entity_id, :id).
          to_a

        next if current_snapshots.empty?

        # Get all entity_ids that have crossings
        entity_ids = current_snapshots.map(&:entity_id).uniq

        # Load all snapshots for these entities in one query to avoid N+1
        # We need all snapshots to find the previous one for each current snapshot
        all_snapshots_for_entities = metric.metric_snapshots.
          where(entity_type: metric.entity_type, entity_id: entity_ids).
          order(:entity_id, :id).
          to_a

        # Group snapshots by entity_id for efficient lookup
        snapshots_by_entity = all_snapshots_for_entities.group_by(&:entity_id)

        # Build crossings array by finding previous snapshot for each current snapshot
        crossings = []
        current_snapshots.each do |snapshot|
          entity_snapshots = snapshots_by_entity[snapshot.entity_id] || []

          # Find the index of current snapshot in the entity's snapshot list
          snapshot_index = entity_snapshots.index { |s| s.id == snapshot.id }

          # Skip if this is the first snapshot (no previous snapshot exists)
          next unless snapshot_index && snapshot_index > 0

          # Get the previous snapshot
          previous_snapshot = entity_snapshots[snapshot_index - 1]

          # Add crossing data
          crossings << {
            entity_id: snapshot.entity_id,
            current_value: snapshot.initial_value,
            previous_value: previous_snapshot.current_value,
          }
        end

        next if crossings.empty?

        # Initialize nested structure if needed
        results[metric.alert_code] ||= {}
        total_count = crossings.count
        truncated = total_count > limit

        results[metric.alert_code][metric.display_name] = {
          data: crossings.first(limit),
          total_count: total_count,
          truncated: truncated,
        }
      end

      results
    end
  end
end
