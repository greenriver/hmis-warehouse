module GrdaWarehouse::WarehouseReports::Dashboard
  class Base < GrdaWarehouse::WarehouseReports::Base
    include ArelHelper

    def self.sub_populations_by_type
      {
        active: {
          veteran: GrdaWarehouse::WarehouseReports::Dashboard::Veteran::ActiveClients,
          all_clients: GrdaWarehouse::WarehouseReports::Dashboard::AllClients::ActiveClients,
          youth: GrdaWarehouse::WarehouseReports::Dashboard::Youth::ActiveClients,
          non_veteran: GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::ActiveClients,
          individual_adults: GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::ActiveClients,
          parenting_children: GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::ActiveClients,
          parenting_youth: GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::ActiveClients,
          children: GrdaWarehouse::WarehouseReports::Dashboard::Children::ActiveClients,
          family: GrdaWarehouse::WarehouseReports::Dashboard::Families::ActiveClients,
        },
        entered: {
          veteran: GrdaWarehouse::WarehouseReports::Dashboard::Veteran::EnteredClients,
          all_clients: GrdaWarehouse::WarehouseReports::Dashboard::AllClients::EnteredClients,
          youth: GrdaWarehouse::WarehouseReports::Dashboard::Youth::EnteredClients,
          non_veteran: GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::EnteredClients,
          individual_adults: GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::EnteredClients,
          parenting_children: GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::EnteredClients,
          parenting_youth: GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::EnteredClients,
          children: GrdaWarehouse::WarehouseReports::Dashboard::Children::EnteredClients,
          family: GrdaWarehouse::WarehouseReports::Dashboard::Families::EnteredClients,
        },
        housed: {
          veteran: GrdaWarehouse::WarehouseReports::Dashboard::Veteran::HousedClients,
          all_clients: GrdaWarehouse::WarehouseReports::Dashboard::AllClients::HousedClients,
          youth: GrdaWarehouse::WarehouseReports::Dashboard::Youth::HousedClients,
          non_veteran: GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::HousedClients,
          individual_adults: GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::HousedClients,
          parenting_children: GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::HousedClients,
          parenting_youth: GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::HousedClients,
          children: GrdaWarehouse::WarehouseReports::Dashboard::Children::HousedClients,
          family: GrdaWarehouse::WarehouseReports::Dashboard::Families::HousedClients,
        }, 
      }
    end

    def self.available_sub_populations
      {
        'All Clients' => :all_clients, 
        'Veterans' => :veteran,
        'Youth' => :youth,
        'Family' => :family,
        'Children' => :children,
        'Parenting Youth' => :parenting_youth,
        'Parenting Juveniles' => :parenting_children,
        'Individual Adults' => :individual_adults,
        'Non-Veterans' => :non_veteran,
      }.sort.to_h.freeze
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def homeless_service_history_source
      scope = service_history_source.
        homeless
      history_scope(scope)
    end

    # def service_counts project_type
    #   homeless_service_history_source.
    #   service_within_date_range(start_date: @range.start, end_date: @range.end).
    #   where(service_history_source.project_type_column => project_type).
    #   group(:client_id).
    #   count
    # end
    
    protected def service_scope project_type
      homeless_service_history_source.
      service_within_date_range(start_date: @range.start, end_date: @range.end).
      where(service_history_source.project_type_column => project_type)
    end

    def enrollment_counts project_type
      service_scope(project_type).
      group(:client_id).
      select(nf('DISTINCT', [ct(sh_t[:enrollment_group_id], '_', sh_t[:data_source_id])]).to_sql).
      count
    end

    def entry_counts project_type
      service_scope(project_type).
      started_between(start_date: @range.start, end_date: @range.end).
      group(:client_id).
      select(nf('DISTINCT', [ct(sh_t[:enrollment_group_id], '_', sh_t[:data_source_id])]).to_sql).
      count
    end

    def entry_dates_by_client project_type
      @entry_dates_by_client = {}
      homeless_service_history_source.
      entry.
      started_between(start_date: @range.start, end_date: @range.end).
      where(service_history_source.project_type_column => project_type).
      where(client_id: service_scope(project_type).distinct.select(:client_id)).
      order(first_date_in_program: :desc).
      pluck(:client_id, :first_date_in_program).
      each do |client_id, first_date_in_program|
        @entry_dates_by_client[client_id] ||= []
        @entry_dates_by_client[client_id] << first_date_in_program
      end
      @entry_dates_by_client
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        where(client_id: client_source.distinct.select(:id))
    end

    def service_history_columns
      {
        client_id: sh_t[:client_id].as('client_id').to_sql, 
        project_id:  sh_t[:project_id].as('project_id').to_sql, 
        first_date_in_program:  sh_t[:first_date_in_program].as('first_date_in_program').to_sql, 
        last_date_in_program:  sh_t[:last_date_in_program].as('last_date_in_program').to_sql, 
        project_name:  sh_t[:project_name].as('project_name').to_sql, 
        project_type:  sh_t[service_history_source.project_type_column].as('project_type').to_sql, 
        organization_id:  sh_t[:organization_id].as('organization_id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
      }
    end

    def colorize(object)
      # make a hash of the object, truncate it to an appropriate size and then turn it into
      # a css friendly hash code
      "#%06x" % (Zlib::crc32(Marshal.dump(object)) & 0xffffff)
    end

    def run_and_save!
      self.started_at = DateTime.now
      self.parameters = self.class.params
      self.data = run!
      self.finished_at = DateTime.now
      save()
    end

  end
end