###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/metric-tracking.md
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
    #
    # How to Test
    #
    # In Rails console (dcr shell bundle exec rails c)
    #
    # First, ensure metric definitions and alert definitions are seeded
    # GrdaWarehouse::Monitoring::MetricDefinition.maintain!
    # GrdaWarehouse::AlertDefinition.maintain!
    #
    # Generate fake data
    # stats = GrdaWarehouse::Monitoring::MetricCalculators::BaseCalculator.generate_fake_data!(num_clients: 50, days_back: 90)
    #
    # The output will show you recent crossing dates, for example:
    # Recent crossing dates (last 7 days):
    #   2025-01-27: 15 crossings
    #   2025-01-28: 22 crossings
    #
    # To test notifications, run:
    #   NotifyMetricThresholdCrossingsJob.perform_now(Date.parse('2025-01-27'))
    #   NotifyMetricThresholdCrossingsJob.perform_now(Date.parse('2025-01-28'))
    #
    # Subscribe a user to alerts (in admin UI or console)
    # user = User.first
    # alert_def = GrdaWarehouse::AlertDefinition.find_by(code: 'metric_days_homeless_threshold')
    # Then assign via admin UI at /admin/users/:id/edit
    #
    # Or manually create subscription:
    # contact = user.system_contact
    # GrdaWarehouse::ContactAlertSubscription.create!(
    #   contact: contact,
    #   alert_definition: alert_def,
    #   active: true,
    # )
    # Run the notification job for a date with crossings
    # NotifyMetricThresholdCrossingsJob.perform_now(Date.parse('2025-01-28'))
    #
    # Returns: Hash with statistics including dates with threshold crossings
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

      stats = {
        total_snapshots: 0,
        crossings_by_date: Hash.new(0),
        recent_crossing_dates: [],
      }

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
        start_date = current_date - days_back.days

        # For each client, generate a timeline of snapshots
        client_ids.each do |client_id|
          # Randomly determine how volatile this client's metric will be
          # 60% stable (few changes), 40% volatile (many changes)
          volatile = rand < 0.4

          # Generate initial baseline value
          baseline_value = generate_realistic_value(metric_definition.name)

          # Determine how many threshold crossings to generate
          if volatile
            # Volatile clients: 5-10 threshold crossings
            num_crossings = rand(5..10)
          else
            # Stable clients: 0-3 threshold crossings
            num_crossings = rand(0..3)
          end

          # Generate dates for threshold crossings, weighted toward recent dates
          crossing_dates = []
          if num_crossings.positive?
            num_crossings.times do |i|
              # Spread crossings across the date range, with bias toward recent dates
              days_offset = if i < num_crossings / 2
                # Earlier crossings spread across first 70% of range
                rand((days_back * 0.3).to_i...(days_back * 0.7).to_i)
              else
                # Later crossings in most recent 30% (higher chance of notifications)
                rand(1...(days_back * 0.3).to_i)
              end
              crossing_dates << (current_date - days_offset.days)
            end
            crossing_dates.sort!
          end

          # Create initial snapshot that spans multiple days
          first_crossing_date = crossing_dates.first || current_date
          initial_span_days = rand(5..20)
          initial_observation_date = start_date
          current_observation_date = [initial_observation_date + initial_span_days.days, first_crossing_date - 1.day].min

          # Allow initial value to drift slightly
          current_value = baseline_value + rand(-2..2)

          snapshots_to_create << {
            entity_type: metric_definition.entity_type,
            entity_id: client_id,
            metric_definition_id: metric_definition.id,
            initial_observation_date: initial_observation_date,
            current_observation_date: current_observation_date,
            initial_value: baseline_value,
            current_value: current_value,
            calculation_version: '1.0.0',
            created_at: initial_observation_date.to_time,
            updated_at: current_observation_date.to_time,
          }

          # Generate snapshots for each threshold crossing
          last_value = current_value
          crossing_dates.each_with_index do |crossing_date, index|
            # Generate new value that crosses threshold
            new_initial_value = generate_threshold_crossing_value(
              last_value,
              metric_definition.count_change_threshold,
            )

            # Determine how long this snapshot should span
            next_crossing = crossing_dates[index + 1]
            span_end = if next_crossing
              # Span until next crossing
              span_days = (next_crossing - crossing_date).to_i - 1
              crossing_date + [span_days, 1].max.days
            else
              # Last crossing - span to current date
              current_date
            end

            # Allow value to drift slightly during the span
            drift = rand(-3..3)
            new_current_value = [new_initial_value + drift, 0].max

            # Create snapshot with initial_observation_date set to the crossing date
            # This ensures notifications will be triggered for this date
            snapshots_to_create << {
              entity_type: metric_definition.entity_type,
              entity_id: client_id,
              metric_definition_id: metric_definition.id,
              initial_observation_date: crossing_date,
              current_observation_date: span_end,
              initial_value: new_initial_value,
              current_value: new_current_value,
              calculation_version: '1.0.0',
              created_at: crossing_date.to_time,
              updated_at: span_end.to_time,
            }

            # Track crossing statistics
            stats[:crossings_by_date][crossing_date] += 1
            stats[:recent_crossing_dates] << crossing_date if crossing_date >= (current_date - 7.days)

            last_value = new_current_value
          end
        end

        # Bulk insert snapshots
        next unless snapshots_to_create.any?

        GrdaWarehouse::Monitoring::MetricSnapshot.insert_all(snapshots_to_create)
        stats[:total_snapshots] += snapshots_to_create.count
        puts "  Created #{snapshots_to_create.count} snapshots for #{client_ids.count} clients"
      end

      stats[:recent_crossing_dates].uniq!.sort!

      puts "\nFake data generation complete!"
      puts "Total snapshots: #{stats[:total_snapshots]}"
      puts "Dates with threshold crossings: #{stats[:crossings_by_date].keys.sort.count}"
      if stats[:recent_crossing_dates].any?
        puts "\nRecent crossing dates (last 7 days):"
        stats[:recent_crossing_dates].each do |date|
          count = stats[:crossings_by_date][date]
          puts "  #{date}: #{count} crossings"
        end
        puts "\nTo test notifications, run:"
        stats[:recent_crossing_dates].each do |date|
          puts "  NotifyMetricThresholdCrossingsJob.perform_now(Date.parse('#{date}'))"
        end
      else
        puts "\nNo recent crossings generated. Generate more data or increase volatility."
      end

      stats
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
