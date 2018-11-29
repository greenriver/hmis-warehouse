module GrdaWarehouse::Census
  class CensusBuilder

    def create_census (start_date, end_date)
      batch_start_date = start_date
      while batch_start_date <= end_date
        # Batches are 1 month, or to the end_date if closer
        batch_end_date = [ batch_start_date + 1.month, end_date ].min

        # By Project Type
        batch_by_project_type = ProjectTypeBatch.new(batch_start_date, batch_end_date)

        GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.keys.each do | project_type |
          batch_by_project_type.build_census_batch(project_type)
        end

        # Remove any existing census data for the batch range
        ByProjectType.delete_all(date: batch_start_date..batch_end_date)
        ByProjectTypeClient.delete_all(date: batch_start_date..batch_end_date)

        # Save the new batch
        batch_by_project_type.by_count.values.each(&:save)
        batch_by_project_type.by_client.values.each(&:save)

        # By Project
        batch_by_project = ProjectBatch.new(batch_start_date, batch_end_date)
        batch_by_project.build_census_batch

        # Remove any existing census data for the batch range
        ByProject.delete_all(date: batch_start_date..batch_end_date)
        ByProjectClient.delete_all(date: batch_start_date..batch_end_date)

        # Save the new batch
        batch_by_project.by_count.values.flat_map do | project |
          project.values.each(&:save)
        end
        batch_by_project.by_client.values.flat_map do | project |
          project.values.each(&:save)
        end

        # Move batch forward
        batch_start_date = batch_end_date + 1.day
      end
    end

    # Delegate to create census data by project type
    class ProjectTypeBatch
      attr_reader :by_count, :by_client

      def initialize(start_date, end_date)
        @by_count = {}
        @by_client = {}
        @start_date = start_date
        @end_date = end_date
      end

      def build_census_batch(project_type_code)
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type_code]

        update_object_map(get_veteran_client_ids(project_type), project_type_code, :veterans)
        update_object_map(get_non_veteran_client_ids(project_type), project_type_code, :non_veterans)
        update_object_map(get_child_client_ids(project_type), project_type_code, :children)
        update_object_map(get_adult_client_ids(project_type), project_type_code, :adults)
        update_object_map(get_youth_client_ids(project_type), project_type_code, :youth)
        update_object_map(get_family_client_ids(project_type), project_type_code, :families)
        update_object_map(get_individual_client_ids(project_type), project_type_code, :individuals)
        update_object_map(get_parenting_youth_client_ids(project_type), project_type_code, :parenting_youth)
        update_object_map(get_parenting_juvenile_client_ids(project_type), project_type_code, :parenting_juveniles)
        update_object_map(get_all_client_ids(project_type), project_type_code, :all_clients)

        # TODO Add homeless_for_date_range to ServiceHistoryService w/ correlated subquery to negate non-homelessness
        @by_client.each do | date, census_row |
          update_object_map(get_homeless_veteran_client_ids(date), :homeless, :veterans)
          update_object_map(get_literally_homeless_veteran_client_ids(date), :literally_homeless, :veterans)
          update_object_map(get_system_veteran_client_ids(date), :system, :veterans)

          update_object_map(get_homeless_non_veteran_client_ids(date), :homeless, :non_veterans)
          update_object_map(get_literally_homeless_non_veteran_client_ids(date), :literally_homeless, :non_veterans)
          update_object_map(get_system_non_veteran_client_ids(date), :system, :non_veterans)

          update_object_map(get_homeless_child_client_ids(date), :homeless, :children)
          update_object_map(get_literally_homeless_child_client_ids(date), :literally_homeless, :children)
          update_object_map(get_system_child_client_ids(date), :system, :children)

          update_object_map(get_homeless_adult_client_ids(date), :homeless, :adults)
          update_object_map(get_literally_homeless_adult_client_ids(date), :literally_homeless, :adults)
          update_object_map(get_system_adult_client_ids(date), :system, :adults)

          update_object_map(get_homeless_youth_client_ids(date), :homeless, :youth)
          update_object_map(get_literally_homeless_youth_client_ids(date), :literally_homeless, :youth)
          update_object_map(get_system_youth_client_ids(date), :system, :youth)

          update_object_map(get_homeless_family_client_ids(date), :homeless, :families)
          update_object_map(get_literally_homeless_family_client_ids(date), :literally_homeless, :families)
          update_object_map(get_system_family_client_ids(date), :system, :families)

          update_object_map(get_homeless_individual_client_ids(date), :homeless, :individuals)
          update_object_map(get_literally_homeless_individual_client_ids(date), :literally_homeless, :individuals)
          update_object_map(get_system_individual_client_ids(date), :system, :individuals)

          update_object_map(get_homeless_parenting_youth_client_ids(date), :homeless, :parenting_youth)
          update_object_map(get_literally_homeless_parenting_youth_client_ids(date), :literally_homeless, :parenting_youth)
          update_object_map(get_system_parenting_youth_client_ids(date), :system, :parenting_youth)

          update_object_map(get_homeless_parenting_juvenile_client_ids(date), :homeless, :parenting_juveniles)
          update_object_map(get_literally_homeless_parenting_juvenile_client_ids(date), :literally_homeless, :parenting_juveniles)
          update_object_map(get_system_parenting_juvenile_client_ids(date), :system, :parenting_juveniles)

          update_object_map(get_homeless_all_clients_client_ids(date), :homeless, :all_clients)
          update_object_map(get_literally_homeless_all_clients_client_ids(date), :literally_homeless, :all_clients)
          update_object_map(get_system_all_clients_client_ids(date), :system, :all_clients)
        end

      end

      def update_object_map (collection, project_type_code, column_name_part)
        column_name = "#{project_type_code}_#{column_name_part}"
        collection.each do | date, client_ids |
          @by_count[date] ||= ByProjectType.new(date: date)
          @by_count[date].write_attribute(column_name, client_ids.size)

          @by_client[date] ||= ByProjectTypeClient.new(date: date)
          @by_client[date].write_attribute(column_name, client_ids)
        end
      end

      # Veteran

      def get_veteran_client_ids (project_type)
        get_client_ids(project_type, :client, GrdaWarehouse::Hud::Client.veteran)
      end


      def get_homeless_veteran_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          [:client, :service_history_enrollment],
          GrdaWarehouse::Hud::Client.veteran,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_veteran_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          [:client, :service_history_enrollment],
          GrdaWarehouse::Hud::Client.veteran,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_veteran_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :client,
          GrdaWarehouse::Hud::Client.veteran)
      end

      # Non-veteran

      def get_non_veteran_client_ids (project_type)
        get_client_ids(project_type, :client, GrdaWarehouse::Hud::Client.non_veteran)
      end

      def get_homeless_non_veteran_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          [:client, :service_history_enrollment],
          GrdaWarehouse::Hud::Client.non_veteran,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_non_veteran_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          [:client, :service_history_enrollment],
          GrdaWarehouse::Hud::Client.non_veteran,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
  end

      def get_system_non_veteran_client_ids (on_date)
        get_aggregate_client_ids(on_date,
         :client,
          GrdaWarehouse::Hud::Client.non_veteran)
      end

      # Child

      def get_child_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.children)
      end

      def get_homeless_child_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
           GrdaWarehouse::ServiceHistoryEnrollment.children,
           GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_child_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.children,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_child_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.children)
      end

      # Adult

      def get_adult_client_ids ( project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.adult)
      end

      def get_homeless_adult_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.adult,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_adult_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.adult,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_adult_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.adult)
      end

      # Youth

      def get_youth_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.youth)
      end

      def get_homeless_youth_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.youth,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_youth_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.youth,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_youth_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.youth)
      end

      # Family

      def get_family_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.family)
      end

      def get_homeless_family_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.family,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_family_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.family,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_family_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.family)
      end

      # Individual

      def get_individual_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.individual)
      end

      def get_homeless_individual_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.individual,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_individual_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.individual,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_individual_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.individual)
      end

      # Parenting Youth

      def get_parenting_youth_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth)
      end

      def get_homeless_parenting_youth_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_parenting_youth_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_parenting_youth_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth)
      end

      # Parenting Juvenile

      def get_parenting_juvenile_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile)
      end

      def get_homeless_parenting_juvenile_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_parenting_juvenile_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_parenting_juvenile_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile)
      end

      # All Clients

      def get_all_client_ids (project_type)
        get_client_ids(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.all_clients)
      end

      def get_homeless_all_clients_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
          GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: on_date))
      end

      def get_literally_homeless_all_clients_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
          GrdaWarehouse::ServiceHistoryEnrollment.hud_currently_homeless(date: on_date))
      end

      def get_system_all_clients_client_ids (on_date)
        get_aggregate_client_ids(on_date,
          :service_history_enrollment,
          GrdaWarehouse::ServiceHistoryEnrollment.all_clients)
      end

      #

      def get_client_ids (project_type, join, client_scope)
        ids = {}
        GrdaWarehouse::ServiceHistoryService.joins(join).service_within_date_range(start_date: @start_date, end_date: @end_date).
            merge(client_scope).where(project_type: project_type).distinct.pluck(:date, :client_id).map do | date, id |
          ids[date] ||= []
          ids[date] << id
        end
        ids
      end

      def get_aggregate_client_ids (date, joins, client_scope, second_scope = nil)
        # Return as map to allow use of update_object_map
        { date => GrdaWarehouse::ServiceHistoryService.joins(*joins).where(date: date).
            merge(client_scope).merge(second_scope).distinct.pluck(:client_id) }
      end
    end

    # Delegate to create census data by project id
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
        update_object_map(get_veteran_client_ids, :veterans)
        update_object_map(get_non_veteran_client_ids, :non_veterans)
        update_object_map(get_child_client_ids, :children)
        update_object_map(get_adult_client_ids, :adults)
        update_object_map(get_youth_client_ids, :youth)
        update_object_map(get_family_client_ids, :families)
        update_object_map(get_individual_client_ids, :individuals)
        update_object_map(get_parenting_youth_client_ids, :parenting_youth)
        update_object_map(get_parenting_juvenile_client_ids, :parenting_juveniles)
        update_object_map(get_all_client_ids, :all_clients)

        @by_count.each do | project_id, census_collection |
          inventories = GrdaWarehouse::Hud::Project.find(project_id).inventories.within_range(start_date..end_date)
          census_collection.each do | date, census_item |
            census_item.beds = inventories.select do | inventory |
              ((inventoryInformationDate.InformationDate.blank? && inventory.InventoryStartDate.blank?) &&
                  (inventory.InventoryEndDate.blank?)) ||
              ((inventoryInformationDate.InformationDate.present? && inventory.InformationDate < date) &&
                  (inventory.InventoryEndDate.blank?)) ||
              ((inventoryInformationDate.InformationDate.present? && inventory.InformationDate < date) &&
                  (inventory.InventoryEndDate.present? && inventory.InventoryEndDate > date)) ||
              ((inventoryInformationDate.InformationDate.blank? && inventory.InventoryStartDate.present? && inventory.InventoryStartDate < date) &&
                  (inventory.InventoryEndDate.blank?)) ||
              ((inventoryInformationDate.InformationDate.blank? && inventory.InventoryStartDate.present? && inventory.InventoryStartDate < date) &&
                  (inventory.InventoryEndDate.present? && inventory.InventoryEndDate > date))
            end.sum(:beds)
          end
        end
      end

      def update_object_map (collection, column_name)
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
end