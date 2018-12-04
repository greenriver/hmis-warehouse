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
      add_clients_to_census_buckets(get_veteran_client_counts, :veterans)
      add_clients_to_census_buckets(get_non_veteran_client_counts, :non_veterans)
      add_clients_to_census_buckets(get_child_client_counts, :children)
      add_clients_to_census_buckets(get_adult_client_counts, :adults)
      add_clients_to_census_buckets(get_youth_client_counts, :youth)
      add_clients_to_census_buckets(get_family_client_counts, :families)
      add_clients_to_census_buckets(get_individual_client_counts, :individuals)
      add_clients_to_census_buckets(get_parenting_youth_client_counts, :parenting_youth)
      add_clients_to_census_buckets(get_parenting_juvenile_client_counts, :parenting_juveniles)
      add_clients_to_census_buckets(get_all_client_counts, :all_clients)

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
          end.sum(&:beds)
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

    def get_veteran_client_counts
      get_client_and_project_counts(GrdaWarehouse::Hud::Client.veteran)
    end

    def get_non_veteran_client_counts
      get_client_and_project_counts(GrdaWarehouse::Hud::Client.non_veteran)
    end

    def get_child_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.children)
    end

    def get_adult_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.adult)
    end

    def get_youth_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.youth)
    end

    def get_family_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.family)
    end

    def get_individual_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.individual)
    end

    def get_parenting_youth_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth)
    end

    def get_parenting_juvenile_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile)
    end

    def get_all_client_counts
      get_client_and_project_counts(GrdaWarehouse::ServiceHistoryEnrollment.all_clients)
    end

    #

    def get_client_and_project_counts (client_scope)
      ids = {}
      GrdaWarehouse::ServiceHistoryService.joins(service_history_enrollment: :project).joins(:client).service_within_date_range(start_date: @start_date, end_date: @end_date).
          merge(client_scope).
          distinct.
          group(:date, p_t[:id].to_sql).
          count(:client_id)
    end
  end
end