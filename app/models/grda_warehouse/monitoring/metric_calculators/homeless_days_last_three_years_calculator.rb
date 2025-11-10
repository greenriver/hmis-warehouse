###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    def self.calculate_batch(entities, _calculation_date)
      entity_ids = entities.map(&:id)

      GrdaWarehouse::WarehouseClientsProcessed.
        service_history.
        where(client_id: entity_ids).
        pluck(:client_id, :days_homeless_last_three_years).
        to_h
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
