###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard
  class Base < GrdaWarehouse::WarehouseReports::Base
    include ArelHelper

    def self.sub_populations_by_type
      Rails.application.config.sub_populations[:by_type] || {
        active: {
          veteran: GrdaWarehouse::WarehouseReports::Dashboard::Veteran::ActiveClients,
          all_clients: GrdaWarehouse::WarehouseReports::Dashboard::AllClients::ActiveClients,
          youth: GrdaWarehouse::WarehouseReports::Dashboard::Youth::ActiveClients,
          non_veteran: GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::ActiveClients,
          individual_adults: GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::ActiveClients,
          parenting_children: GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::ActiveClients,
          parenting_youth: GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::ActiveClients,
          family_parents: GrdaWarehouse::WarehouseReports::Dashboard::Parents::ActiveClients,
          children: GrdaWarehouse::WarehouseReports::Dashboard::Children::ActiveClients,
          unaccompanied_minors: GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors::ActiveClients,
          family: GrdaWarehouse::WarehouseReports::Dashboard::Families::ActiveClients,
          youth_families: GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies::ActiveClients,
        },
        entered: {
          veteran: GrdaWarehouse::WarehouseReports::Dashboard::Veteran::EnteredClients,
          all_clients: GrdaWarehouse::WarehouseReports::Dashboard::AllClients::EnteredClients,
          youth: GrdaWarehouse::WarehouseReports::Dashboard::Youth::EnteredClients,
          non_veteran: GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::EnteredClients,
          individual_adults: GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::EnteredClients,
          parenting_children: GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::EnteredClients,
          parenting_youth: GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::EnteredClients,
          family_parents: GrdaWarehouse::WarehouseReports::Dashboard::Parents::EnteredClients,
          children: GrdaWarehouse::WarehouseReports::Dashboard::Children::EnteredClients,
          unaccompanied_minors: GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors::EnteredClients,
          family: GrdaWarehouse::WarehouseReports::Dashboard::Families::EnteredClients,
          youth_families: GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies::EnteredClients,
        },
        housed: {
          veteran: GrdaWarehouse::WarehouseReports::Dashboard::Veteran::HousedClients,
          all_clients: GrdaWarehouse::WarehouseReports::Dashboard::AllClients::HousedClients,
          youth: GrdaWarehouse::WarehouseReports::Dashboard::Youth::HousedClients,
          non_veteran: GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::HousedClients,
          individual_adults: GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::HousedClients,
          parenting_children: GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::HousedClients,
          parenting_youth: GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::HousedClients,
          family_parents: GrdaWarehouse::WarehouseReports::Dashboard::Parents::HousedClients,
          children: GrdaWarehouse::WarehouseReports::Dashboard::Children::HousedClients,
          unaccompanied_minors: GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors::HousedClients,
          family: GrdaWarehouse::WarehouseReports::Dashboard::Families::HousedClients,
          youth_families: GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies::HousedClients,
        },
      }
    end

    def self.tabs
      Rails.application.config.sub_populations[:tabs] || {
        'census' => {
          title: 'Census',
          path: ['censuses'],
        },
        'clients' => {
          title: 'Client',
          path: ['dashboards_clients'],
        },
        'individual_adults'  => {
          title: 'Adults',
          path: ['dashboards_individual_adults'],
        },
        'veteran'  => {
          title: 'Veteran',
          path: ['dashboards_veterans'],
        },
        'non_veteran'  => {
          title: 'Non-Veteran',
          path: ['dashboards_non_veterans'],
        },
        'family'  => {
          title: 'Family',
          path: ['dashboards_families'],
        },
        'youth_families'  => {
          title: 'Youth Families',
          path: ['dashboards_youth_families'],
        },
        'youths'  => {
          title: 'Youth',
          path: ['dashboards_youths'],
        },
        'family_parents' => {
          title: 'Parents',
          path: ['dashboards_family_parents'],
        },
        'parenting_youth'  => {
          title: 'Youth Parents',
          path: ['dashboards_parenting_youths'],
        },
        'children_only'  => {
          title: 'Children',
          path: ['dashboards_childrens'],
        },
        'parenting_children'  => {
          title: 'Juvenile Parents',
          path: ['dashboards_parenting_childrens'],
        },
        'unaccompanied_minors'  => {
          title: 'Unaccompanied Minors',
          path: ['dashboards_unaccompanied_minors'],
        },
      }
    end

    def self.available_sub_populations
      Rails.application.config.sub_populations[:available] || {
        'All Clients' => :all_clients,
        'Veterans' => :veteran,
        'Youth' => :youth,
        'Family' => :family,
        'Youth Families' => :youth_families,
        'Children' => :children,
        'Parents' => :family_parents,
        'Parenting Youth' => :parenting_youth,
        'Parenting Juveniles' => :parenting_children,
        'Unaccompanied Minors' => :unaccompanied_minors,
        'Individual Adults' => :individual_adults,
        'Non-Veterans' => :non_veteran,
      }.sort.to_h
    end

    def self.add_sub_population(name, symbol, package)
      sub_populations = available_sub_populations
      sub_populations[name] = symbol
      Rails.application.config.sub_populations[:available] = sub_populations.sort.to_h

      tab_hash = tabs
      tab_hash[symbol.to_s] = {
        title: name,
        path: ['dashboards', symbol],
      }
      Rails.application.config.sub_populations[:tabs] = tab_hash

      types = sub_populations_by_type
      types[:active][symbol] = "#{package}::ActiveClients".constantize
      types[:entered][symbol] = "#{package}::EnteredClients".constantize
      types[:housed][symbol] = "#{package}::HousedClients".constantize
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
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

    def service_scope project_type
      homeless_service_history_source.
      with_service_between(start_date: @range.start, end_date: @range.end).
      open_between(start_date: @range.start, end_date: @range.end).
      in_project_type(project_type)
    end

    def enrollment_counts project_type
      service_scope(project_type).
      group(:client_id).
      select(nf('DISTINCT', [ct(she_t[:enrollment_group_id], '_', she_t[:data_source_id], '_', she_t[:project_id])]).to_sql).
      count
    end

    def entry_counts project_type
      service_scope(project_type).
      started_between(start_date: @range.start, end_date: @range.end).
      group(:client_id).
      select(nf('DISTINCT', [ct(she_t[:enrollment_group_id], '_', she_t[:data_source_id], '_', she_t[:project_id])]).to_sql).
      count
    end

    def entry_dates_by_client project_type
      @entry_dates_by_client = {}
      # limit to clients with an entry within the range and service within the range in the type
      involved_client_ids = homeless_service_history_source.
        entry.
        started_between(start_date: @range.start, end_date: @range.end).
        in_project_type(project_type).
        with_service_between(start_date: @range.start, end_date: @range.end).
        distinct.
        select(:client_id)
      # get all of their entry records regardless of date range
      homeless_service_history_source.
        entry.
        where(client_id: involved_client_ids).
        where(she_t[:first_date_in_program].lteq(@range.end)).
        in_project_type(project_type).
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
        client_id: she_t[:client_id].as('client_id').to_sql,
        project_id:  she_t[:project_id].as('project_id').to_sql,
        first_date_in_program:  she_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program:  she_t[:last_date_in_program].as('last_date_in_program').to_sql,
        project_name:  she_t[:project_name].as('project_name').to_sql,
        project_type:  she_t[service_history_source.project_type_column].as('project_type').to_sql,
        organization_id:  she_t[:organization_id].as('organization_id').to_sql,
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