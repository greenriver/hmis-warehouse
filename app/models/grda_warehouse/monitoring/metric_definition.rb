###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring
  class MetricDefinition < GrdaWarehouseBase
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

    # Initialize default metric definitions
    # Called once via TaskQueue to populate the table
    def self.maintain!
      available_calculators.each do |calculator_class|
        attrs = calculator_class.metric_definition_attributes
        find_or_create_by!(
          name: attrs[:name],
          entity_type: attrs[:entity_type],
        ) do |metric|
          metric.assign_attributes(attrs)
        end
      end
    end

    # Get chart data showing threshold crossings over time
    # Returns array of [date_string, count] for days where entities crossed threshold
    # Excludes initial observations (first snapshot for each entity/metric)
    def threshold_crossing_data(days_back:)
      start_date = days_back.days.ago.to_date
      end_date = Date.current

      # Find initial snapshot IDs (first snapshot for each entity/metric combination)
      initial_snapshot_ids = metric_snapshots.
        select('MIN(id)').
        group(:entity_type, :entity_id, :metric_definition_id)

      # Get non-initial snapshots created in the date range
      # Group by creation date and count entities
      crossings = metric_snapshots.
        where('DATE(created_at) >= ?', start_date).
        where('DATE(created_at) <= ?', end_date).
        where.not(id: initial_snapshot_ids).
        group('DATE(created_at)').
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
  end
end
