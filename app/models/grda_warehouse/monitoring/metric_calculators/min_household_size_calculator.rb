###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring::MetricCalculators
  class MinHouseholdSizeCalculator < BaseCalculator
    include ArelHelper

    # Batch calculation for multiple clients
    # Returns hash of { client_id => min_size }
    def self.calculate_batch(entities, _calculation_date)
      entity_ids = entities.map(&:id)

      # First, get count of members for each [data_source_id, HouseholdID] combination
      household_sizes = GrdaWarehouse::Hud::Enrollment.
        group(:data_source_id, :HouseholdID).
        count(:HouseholdID)

      # Then get which households each client has been in
      client_households = GrdaWarehouse::Hud::Enrollment.
        joins(client: :warehouse_client_source).
        where(wc_t[:destination_id].in(entity_ids)).
        pluck(wc_t[:destination_id], :data_source_id, :HouseholdID)

      # For each client, look up their household sizes and find min
      client_households.
        group_by { |client_id, _ds_id, _hh_id| client_id }.
        transform_values do |households|
          sizes = households.map do |_client_id, ds_id, hh_id|
            household_sizes[[ds_id, hh_id]]
          end.compact
          sizes.empty? ? nil : sizes.min
        end.
        compact
    end

    def self.metric_definition_attributes
      {
        name: 'min_household_size',
        display_name: 'Minimum Household Size',
        description: 'Tracks the smallest household size across all enrollments. Household size is calculated as the count of members for each unique [data_source_id, HouseholdID] combination. Creates new snapshot on any change.',
        entity_type: 'GrdaWarehouse::Hud::Client',
        calculator_class: name,
        category: 'demographics',
        count_change_threshold: 1,
        percent_change_threshold: nil,
        active: true,
      }
    end
  end
end
