###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/metric-tracking.md
module GrdaWarehouse::Monitoring::MetricCalculators
  class HomelessDaysLastThreeYearsCalculator < BaseCalculator
    def calculate
      processed = GrdaWarehouse::WarehouseClientsProcessed.
        service_history.
        find_by(client_id: entity.id)

      processed&.days_homeless_last_three_years
    end

    # Efficient batch calculation - single query for all entities
    # Returns hash of { client_id => value } for clients with data
    # Clients not found are omitted (no snapshot will be created)
    # Note: calculation_date not used since warehouse_clients_processed
    # maintains a rolling 3-year window
    def self.calculate_batch(entities, _calculation_date, **_kwargs)
      entity_ids = entities.map(&:id)

      GrdaWarehouse::WarehouseClientsProcessed.
        service_history.
        where(client_id: entity_ids).
        pluck(:client_id, :days_homeless_last_three_years).
        to_h
    end

    # days_homeless_last_three_years is a rolling-window total that drifts a little each
    # day. Measure the change against the previous run's value (current_value) rather than
    # the original baseline, and normalize by the number of days since that run, so a
    # crossing reflects a real per-day jump rather than gradual accumulation (or a
    # multi-day catch-up after a missed run).
    def self.change_metrics(previous_snapshot:, calculated_value:, calculation_date:)
      days_elapsed = (calculation_date - previous_snapshot.current_observation_date).to_i
      days_elapsed = 1 if days_elapsed < 1

      baseline = previous_snapshot.current_value
      count_change = (calculated_value - baseline).abs.to_f / days_elapsed
      {
        count_change: count_change,
        percent_change: baseline.zero? ? nil : (count_change / baseline.abs * 100),
      }
    end

    # warehouse_clients_processed is written by UpdateWarehouseClientsCachesJob.
    # Try to acquire its advisory lock non-blocking; if we get it, no batch is
    # actively writing right now and we release immediately.
    def self.data_stable?
      stable = false
      GrdaWarehouseBase.with_advisory_lock(UpdateWarehouseClientsCachesJob::ADVISORY_LOCK_NAME, timeout_seconds: 0) do
        stable = true
      end
      stable
    end

    # Return metric definition attributes for this calculator
    def self.metric_definition_attributes
      {
        name: 'days_homeless_last_three_years',
        entity_type: 'GrdaWarehouse::Hud::Client',
        display_name: 'Days Homeless (Last 3 Years)',
        description: 'Total days homeless in the last 3 years from warehouse_clients_processed',
        calculator_class: name,
        category: 'client_services',
        calculation_window_days: 1095, # 3 years
        count_change_threshold: 30, # Alert if changes by 30+ days
        percent_change_threshold: nil,
        active: false,
        alert_code: 'metric_days_homeless_threshold',
      }
    end
  end
end
