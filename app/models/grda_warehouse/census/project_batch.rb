# Delegate to create census data by project id
module GrdaWarehouse::Census
  class ProjectBatch
    include ArelHelper

    attr_reader :by_count, :by_client

    def initialize(start_date, end_date)
      @by_count = {}
      @by_client = {}
      @start_date = start_date
      @end_date = end_date
    end

    def build_census_batch
      add_clients_to_census_buckets(get_veteran_client_ids, :veterans)
      add_clients_to_census_buckets(get_non_veteran_client_ids, :non_veterans)
      add_clients_to_census_buckets(get_child_client_ids, :children)
      add_clients_to_census_buckets(get_adult_client_ids, :adults)
      add_clients_to_census_buckets(get_youth_client_ids, :youth)
      add_clients_to_census_buckets(get_family_client_ids, :families)
      add_clients_to_census_buckets(get_individual_client_ids, :individuals)
      add_clients_to_census_buckets(get_parenting_youth_client_ids, :parenting_youth)
      add_clients_to_census_buckets(get_parenting_juvenile_client_ids, :parenting_juveniles)
      add_clients_to_census_buckets(get_all_client_ids, :all_clients)

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
      collection.each do | project_id, census_collection |
        census_collection.each do | date, client_ids |
          @by_count[project_id] ||= {}
          @by_count[project_id][date] ||= ByProject.new(project_id: project_id, date: date)
          @by_count[project_id][date].write_attribute(column_name, client_ids.size)

          @by_client[project_id] ||= {}
          @by_client[project_id][date] ||= ByProjectClient.new(project_id: project_id, date: date)
          @by_client[project_id][date].write_attribute(column_name, client_ids)
        end
      end
    end

    def get_veteran_client_ids
      get_client_and_project_ids(GrdaWarehouse::Hud::Client.veteran)
    end

    def get_non_veteran_client_ids
      get_client_and_project_ids(GrdaWarehouse::Hud::Client.non_veteran)
    end

    def get_child_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.children)
    end

    def get_adult_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.adult)
    end

    def get_youth_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.youth)
    end

    def get_family_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.family)
    end

    def get_individual_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.individual)
    end

    def get_parenting_youth_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth)
    end

    def get_parenting_juvenile_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile)
    end

    def get_all_client_ids
      get_client_and_project_ids(GrdaWarehouse::ServiceHistoryEnrollment.all_clients)
    end

    #

    def get_client_and_project_ids (client_scope)
      ids = {}
      GrdaWarehouse::ServiceHistoryService.joins(service_history_enrollment: :project).joins(:client).service_within_date_range(start_date: @start_date, end_date: @end_date).
          merge(client_scope).distinct.pluck(:date, :client_id, p_t[:id].to_sql).map do | date, id, project_id |
        ids[project_id] ||= {}
        ids[project_id][date] ||= []
        ids[project_id][date] << id
      end
      ids
    end
  end
end