###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring::MetricCalculators
  class BaseCalculator
    attr_reader :entity, :calculation_date

    def initialize(entity, calculation_date)
      @entity = entity
      @calculation_date = calculation_date
    end

    # Instance method - calculate for single entity
    # Subclasses should implement this OR override calculate_batch
    def calculate
      raise NotImplementedError, "#{self.class} must implement #calculate"
    end

    # Class method - calculate for batch of entities
    # Returns hash of { entity_id => value }
    # Subclasses should override this for efficient batch processing
    def self.calculate_batch(entities, calculation_date)
      entities.to_h do |entity|
        [entity.id, new(entity, calculation_date).calculate]
      end
    end

    # Return calculation version
    def version
      '1.0.0'
    end

    # Helper: get lookback window
    def lookback_window
      metric_definition&.calculation_window_days&.days || 3.years
    end

    def lookback_start_date
      calculation_date - lookback_window
    end

    # Generate fake metric snapshots for development/testing
    # Creates realistic data with threshold crossings over the last 90 days
    # Only runs in development or test environments
    def self.generate_fake_data!(num_clients: 50, days_back: 90)
      raise 'Fake data generation only allowed in development or test environments' unless Rails.env.development? || Rails.env.test?

      puts "Generating fake metric data for #{days_back} days..."

      # Get actual client IDs from database
      client_ids = GrdaWarehouse::Hud::Client.
        destination.
        limit(num_clients).
        pluck(:id)

      if client_ids.empty?
        puts 'No clients found in database. Cannot generate fake data.'
        return
      end

      # Process each calculator
      GrdaWarehouse::Monitoring::MetricDefinition.available_calculators.each do |calculator_class|
        puts "\nGenerating data for #{calculator_class.name}..."

        metric_definition = GrdaWarehouse::Monitoring::MetricDefinition.find_by(
          calculator_class: calculator_class.name,
        )

        unless metric_definition
          puts '  Metric definition not found, skipping...'
          next
        end

        snapshots_to_create = []
        current_date = Date.current

        # For each client, generate a timeline of snapshots
        client_ids.each do |client_id|
          # Randomly determine how volatile this client's metric will be
          # 70% stable (few changes), 30% volatile (many changes)
          volatile = rand < 0.3

          # Generate initial baseline value
          baseline_value = generate_realistic_value(metric_definition.name)
          initial_date = current_date - days_back.days

          # Create initial snapshot
          snapshots_to_create << {
            entity_type: metric_definition.entity_type,
            entity_id: client_id,
            metric_definition_id: metric_definition.id,
            initial_observation_date: initial_date,
            current_observation_date: initial_date,
            initial_value: baseline_value,
            current_value: baseline_value,
            calculation_version: '1.0.0',
            created_at: initial_date.to_time,
            updated_at: initial_date.to_time,
          }

          # Generate subsequent snapshots with threshold crossings
          if volatile
            # Volatile clients: 5-10 threshold crossings
            num_crossings = rand(5..10)
          else
            # Stable clients: 0-2 threshold crossings
            num_crossings = rand(0..2)
          end

          last_value = baseline_value
          last_date = initial_date

          num_crossings.times do
            # Generate a date between last crossing and now
            crossing_date = last_date + rand(5..(days_back / (num_crossings + 1))).days
            break if crossing_date > current_date

            # Generate new value that crosses threshold
            new_value = generate_threshold_crossing_value(
              last_value,
              metric_definition.count_change_threshold,
            )

            snapshots_to_create << {
              entity_type: metric_definition.entity_type,
              entity_id: client_id,
              metric_definition_id: metric_definition.id,
              initial_observation_date: crossing_date,
              current_observation_date: crossing_date,
              initial_value: new_value,
              current_value: new_value,
              calculation_version: '1.0.0',
              created_at: crossing_date.to_time,
              updated_at: crossing_date.to_time,
            }

            last_value = new_value
            last_date = crossing_date
          end
        end

        # Bulk insert snapshots
        if snapshots_to_create.any?
          GrdaWarehouse::Monitoring::MetricSnapshot.insert_all(snapshots_to_create)
          puts "  Created #{snapshots_to_create.count} snapshots for #{client_ids.count} clients"
        end
      end

      puts "\nFake data generation complete!"
    end

    # Generate realistic starting values based on metric type
    def self.generate_realistic_value(metric_name)
      case metric_name
      when 'days_homeless_last_three_years'
        rand(0..500)
      when 'min_household_size', 'max_household_size'
        rand(1..6)
      else
        rand(0..100)
      end
    end

    # Generate a value that crosses the threshold
    def self.generate_threshold_crossing_value(previous_value, threshold)
      return previous_value + rand(50..100) unless threshold

      # Ensure the change exceeds the threshold
      direction = rand > 0.5 ? 1 : -1
      change = threshold + rand(10..50)
      new_value = previous_value + (direction * change)

      # Keep values realistic (non-negative for most metrics)
      [new_value, 0].max
    end

    private

    def metric_definition
      @metric_definition ||= GrdaWarehouse::Monitoring::MetricDefinition.find_by(
        calculator_class: self.class.name,
      )
    end
  end
end
