###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      GrdaWarehouse::Census.census_populations.each do |population|
        scope = GrdaWarehouse::ServiceHistoryEnrollment.public_send(population[:population])
        add_clients_to_census_buckets(
          get_client_and_project_counts(scope),
          population[:population]
        )
      end

      @by_count.each do | project_id, census_collection |
        inventories = GrdaWarehouse::Hud::Project.find(project_id).inventories.within_range(@start_date..@end_date)
        census_collection.each do | date, census_item |
          census_item.beds = inventories.select do | inventory |
            ((inventory.InformationDate.blank? && inventory.InventoryStartDate.blank?) &&
                (inventory.InventoryEndDate.blank?)) ||
            ((inventory.InformationDate.present? && inventory.InformationDate < date) &&
                (inventory.InventoryEndDate.blank?)) ||
            ((inventory.InformationDate.present? && inventory.InformationDate < date) &&
                (inventory.InventoryEndDate.present? && inventory.InventoryEndDate > date)) ||
            ((inventory.InformationDate.blank? && inventory.InventoryStartDate.present? && inventory.InventoryStartDate < date) &&
                (inventory.InventoryEndDate.blank?)) ||
            ((inventory.InformationDate.blank? && inventory.InventoryStartDate.present? && inventory.InventoryStartDate < date) &&
                (inventory.InventoryEndDate.present? && inventory.InventoryEndDate > date))
          end.sum(&:beds) rescue 0
        end
      end
    end

    def add_clients_to_census_buckets (collection, column_name)
      collection.each do | (date, project_id), count |
        @by_count[project_id] ||= {}
        @by_count[project_id][date] ||= ByProject.new(project_id: project_id, date: date)
        @by_count[project_id][date].write_attribute(column_name, count)
      end
    end

    def get_client_and_project_counts (client_scope)
      ids = {}
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
