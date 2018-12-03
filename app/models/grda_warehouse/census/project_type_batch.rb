# Delegate to create census data by project type
module GrdaWarehouse::Census
  class ProjectTypeBatch
    attr_reader :by_count, :by_client

    def initialize(start_date, end_date)
      @by_count = {}
      @start_date = start_date
      @end_date = end_date
    end

    def build_batch_for_project_type(project_type_code)
      project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type_code]

      add_clients_to_census_buckets(get_veteran_client_counts(project_type), project_type_code, :veterans)
      add_clients_to_census_buckets(get_non_veteran_client_counts(project_type), project_type_code, :non_veterans)
      add_clients_to_census_buckets(get_child_client_counts(project_type), project_type_code, :children)
      add_clients_to_census_buckets(get_adult_client_counts(project_type), project_type_code, :adults)
      add_clients_to_census_buckets(get_youth_client_counts(project_type), project_type_code, :youth)
      add_clients_to_census_buckets(get_family_client_counts(project_type), project_type_code, :families)
      add_clients_to_census_buckets(get_individual_client_counts(project_type), project_type_code, :individuals)
      add_clients_to_census_buckets(get_parenting_youth_client_counts(project_type), project_type_code, :parenting_youth)
      add_clients_to_census_buckets(get_parenting_juvenile_client_counts(project_type), project_type_code, :parenting_juveniles)
      add_clients_to_census_buckets(get_all_client_counts(project_type), project_type_code, :all_clients)

    end

    def build_project_type_independent_batch
      add_clients_to_census_buckets(get_homeless_veteran_client_counts(), :homeless, :veterans)
      add_clients_to_census_buckets(get_literally_homeless_veteran_client_counts(), :literally_homeless, :veterans)
      add_clients_to_census_buckets(get_system_veteran_client_counts(), :system, :veterans)

      add_clients_to_census_buckets(get_homeless_non_veteran_client_counts(), :homeless, :non_veterans)
      add_clients_to_census_buckets(get_literally_homeless_non_veteran_client_counts(), :literally_homeless, :non_veterans)
      add_clients_to_census_buckets(get_system_non_veteran_client_counts(), :system, :non_veterans)

      add_clients_to_census_buckets(get_homeless_child_client_counts(), :homeless, :children)
      add_clients_to_census_buckets(get_literally_homeless_child_client_counts(), :literally_homeless, :children)
      add_clients_to_census_buckets(get_system_child_client_counts(), :system, :children)

      add_clients_to_census_buckets(get_homeless_adult_client_counts(), :homeless, :adults)
      add_clients_to_census_buckets(get_literally_homeless_adult_client_counts(), :literally_homeless, :adults)
      add_clients_to_census_buckets(get_system_adult_client_counts(), :system, :adults)

      add_clients_to_census_buckets(get_homeless_youth_client_counts(), :homeless, :youth)
      add_clients_to_census_buckets(get_literally_homeless_youth_client_counts(), :literally_homeless, :youth)
      add_clients_to_census_buckets(get_system_youth_client_counts(), :system, :youth)

      add_clients_to_census_buckets(get_homeless_family_client_counts(), :homeless, :families)
      add_clients_to_census_buckets(get_literally_homeless_family_client_counts(), :literally_homeless, :families)
      add_clients_to_census_buckets(get_system_family_client_counts(), :system, :families)

      add_clients_to_census_buckets(get_homeless_individual_client_counts(), :homeless, :individuals)
      add_clients_to_census_buckets(get_literally_homeless_individual_client_counts(), :literally_homeless, :individuals)
      add_clients_to_census_buckets(get_system_individual_client_counts(), :system, :individuals)

      add_clients_to_census_buckets(get_homeless_parenting_youth_client_counts(), :homeless, :parenting_youth)
      add_clients_to_census_buckets(get_literally_homeless_parenting_youth_client_counts(), :literally_homeless, :parenting_youth)
      add_clients_to_census_buckets(get_system_parenting_youth_client_counts(), :system, :parenting_youth)

      add_clients_to_census_buckets(get_homeless_parenting_juvenile_client_counts(), :homeless, :parenting_juveniles)
      add_clients_to_census_buckets(get_literally_homeless_parenting_juvenile_client_counts(), :literally_homeless, :parenting_juveniles)
      add_clients_to_census_buckets(get_system_parenting_juvenile_client_counts(), :system, :parenting_juveniles)

      add_clients_to_census_buckets(get_homeless_all_clients_client_counts(), :homeless, :all_clients)
      add_clients_to_census_buckets(get_literally_homeless_all_clients_client_counts(), :literally_homeless, :all_clients)
      add_clients_to_census_buckets(get_system_all_clients_client_counts(), :system, :all_clients)


    end

    def add_clients_to_census_buckets(collection, project_type_code, column_name_part)
      column_name = "#{project_type_code}_#{column_name_part}"
      collection.each do | date, count |
        @by_count[date] ||= ByProjectType.new(date: date)
        @by_count[date][column_name] = count
      end
    end

    # Veteran

    def get_veteran_client_counts(project_type)
      get_client_counts(project_type, :client, GrdaWarehouse::Hud::Client.veteran)
    end


    def get_homeless_veteran_client_counts ()
      get_aggregate_client_counts(
        joins: :client,
        client_scope: GrdaWarehouse::Hud::Client.veteran,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_veteran_client_counts
      get_aggregate_client_counts(
        joins: :client,
        client_scope: GrdaWarehouse::Hud::Client.veteran,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_veteran_client_counts 
      get_aggregate_client_counts(
        joins: :client,
        client_scope: GrdaWarehouse::Hud::Client.veteran
      )
    end

    # Non-veteran

    def get_non_veteran_client_counts (project_type)
      get_client_counts(project_type, :client, GrdaWarehouse::Hud::Client.non_veteran)
    end

    def get_homeless_non_veteran_client_counts 
      get_aggregate_client_counts(
        joins: :client,
        client_scope: GrdaWarehouse::Hud::Client.non_veteran,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_non_veteran_client_counts 
      get_aggregate_client_counts(
        joins: :client,
        client_scope: GrdaWarehouse::Hud::Client.non_veteran,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_non_veteran_client_counts 
      get_aggregate_client_counts(
       joins: :client,
       client_scope:  GrdaWarehouse::Hud::Client.non_veteran
      )
    end

    # Child

    def get_child_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.children)
    end

    def get_homeless_child_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope:  GrdaWarehouse::ServiceHistoryEnrollment.children,
        second_scope:  GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_child_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.children,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_child_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.children
      )
    end

    # Adult

    def get_adult_client_counts ( project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.adult)
    end

    def get_homeless_adult_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.adult,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_adult_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.adult,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
        )
    end

    def get_system_adult_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.adult
      )
    end

    # Youth

    def get_youth_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.youth)
    end

    def get_homeless_youth_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_youth_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_youth_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth
      )
    end

    # Family

    def get_family_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.family)
    end

    def get_homeless_family_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_family_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_family_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family
      )
    end

    # Individual

    def get_individual_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.individual)
    end

    def get_homeless_individual_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.individual,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_individual_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.individual,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_individual_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.individual
      )
    end

    # Parenting Youth

    def get_parenting_youth_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth)
    end

    def get_homeless_parenting_youth_client_counts 
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_parenting_youth_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_parenting_youth_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth
      )
    end

    # Parenting Juvenile

    def get_parenting_juvenile_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile)
    end

    def get_homeless_parenting_juvenile_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_parenting_juvenile_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
        second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_parenting_juvenile_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile
      )
    end

    # All Clients

    def get_all_client_counts (project_type)
      get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.all_clients)
    end

    def get_homeless_all_clients_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
        second_scope: GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_literally_homeless_all_clients_client_counts
      get_aggregate_client_counts(
       joins: :service_history_enrollment,
       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_only(start_date: @start_date, end_date: @end_date)
      )
    end

    def get_system_all_clients_client_counts
      get_aggregate_client_counts(
        joins: :service_history_enrollment,
        client_scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients
      )
    end

    #

    def get_client_counts(project_type, join, client_scope)
      ids = {}
      GrdaWarehouse::ServiceHistoryService.joins(join).
        service_within_date_range(start_date: @start_date, end_date: @end_date).
          merge(client_scope).
          where(project_type: project_type).
          distinct.
          group(:date).
          count(:client_id)
    end

    def get_aggregate_client_counts(joins:, client_scope:, second_scope: nil)
      ids = {}
      GrdaWarehouse::ServiceHistoryService.joins(*joins).
        where(date: (@start_date..@end_date)).
        merge(client_scope).
        merge(second_scope).
        distinct.
        group(:date).
        count(:client_id)
    end
  end
end
