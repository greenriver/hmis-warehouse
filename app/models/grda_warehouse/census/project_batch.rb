# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Delegate to create census data by project id
module GrdaWarehouse::Census
  class ProjectBatch
    include ArelHelper

    attr_reader :by_count, :by_client

    def initialize(start_date, end_date)
      @by_count = {}
      @start_date = start_date
      @end_date = end_date
    end

    def build_census_batch
      populations = GrdaWarehouse::Census.census_populations.map { |p| p[:population] }.uniq
      populations.each do |population|
        scope = GrdaWarehouse::ServiceHistoryEnrollment.public_send(population)
        add_clients_to_census_buckets(get_client_and_project_counts(scope), population)
      end

      @by_count.each do |project_id, census_collection|
        inventories = GrdaWarehouse::Hud::Project.find(project_id).inventories.within_range(@start_date..@end_date)
        census_collection.each do |date, census_item|
          filtered_inventory = inventories.filter { |inventory| inventory_active_on_date?(inventory, date) }
          beds = filtered_inventory.map(&:beds).compact
          beds = [0] if beds.empty?
          # preserve behavior of returning 0 if any bed values are nil (rather than compact.sum)
          census_item.beds = beds.sum
        end
      end
    end

    def inventory_active_on_date?(inventory, date)
      # Always active if all dates are blank
      if inventory.InformationDate.blank? &&
         inventory.InventoryStartDate.blank? &&
         inventory.InventoryEndDate.blank?
        return true
      end

      # Determine the effective start date (InfoDate takes precedence)
      start_date = inventory.InformationDate || inventory.InventoryStartDate
      end_date = inventory.InventoryEndDate

      # If we have a start date but no end date, active from start onward
      return true if start_date && !end_date && start_date <= date

      # If we have both start and end dates, check if date is in range (inclusive)
      return true if start_date && end_date && date.between?(start_date, end_date)

      false
    end

    def add_clients_to_census_buckets(collection, column_name)
      collection.each do |(date, project_id), count|
        @by_count[project_id] ||= {}
        @by_count[project_id][date] ||= ByProject.new(project_id: project_id, date: date)
        @by_count[project_id][date].write_attribute(column_name, count)
      end
    end

    def get_client_and_project_counts(client_scope)
      GrdaWarehouse::ServiceHistoryService.
        joins(service_history_enrollment: :project).
        joins(:client).service_within_date_range(start_date: @start_date, end_date: @end_date).
        merge(client_scope).
        distinct.
        group(:date, p_t[:id].to_sql).
        count(:client_id)
    end
  end
end
