###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AvailableSubPopulations
  extend ActiveSupport::Concern

  included do
    def self.sub_populations_by_type
      AvailableSubPopulations.sub_populations_by_type
    end

    def self.available_sub_populations
      AvailableSubPopulations.available_sub_populations
    end
  end

  def self.sub_populations_by_type
    Rails.application.config.sub_populations[:by_type] || {
      active: {
        #   veteran: 'GrdaWarehouse::WarehouseReports::Dashboard::Veteran::ActiveClients',
        #   all_clients: 'GrdaWarehouse::WarehouseReports::Dashboard::AllClients::ActiveClients',
        #   youth: 'GrdaWarehouse::WarehouseReports::Dashboard::Youth::ActiveClients',
        #   non_veteran: 'GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::ActiveClients',
        #   individual_adults: 'GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::ActiveClients',
        #   parenting_children: 'GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::ActiveClients',
        #   parenting_youth: 'GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::ActiveClients',
        #   family_parents: 'GrdaWarehouse::WarehouseReports::Dashboard::Parents::ActiveClients',
        #   children: 'GrdaWarehouse::WarehouseReports::Dashboard::Children::ActiveClients',
        #   unaccompanied_minors: 'GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors::ActiveClients',
        #   family: 'GrdaWarehouse::WarehouseReports::Dashboard::Families::ActiveClients',
        #   youth_families: 'GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies::ActiveClients',
      },
      entered: {
        #   veteran: 'GrdaWarehouse::WarehouseReports::Dashboard::Veteran::EnteredClients',
        #   all_clients: 'GrdaWarehouse::WarehouseReports::Dashboard::AllClients::EnteredClients',
        #   youth: 'GrdaWarehouse::WarehouseReports::Dashboard::Youth::EnteredClients',
        #   non_veteran: 'GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::EnteredClients',
        #   individual_adults: 'GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::EnteredClients',
        #   parenting_children: 'GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::EnteredClients',
        #   parenting_youth: 'GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::EnteredClients',
        #   family_parents: 'GrdaWarehouse::WarehouseReports::Dashboard::Parents::EnteredClients',
        #   children: 'GrdaWarehouse::WarehouseReports::Dashboard::Children::EnteredClients',
        #   unaccompanied_minors: 'GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors::EnteredClients',
        #   family: 'GrdaWarehouse::WarehouseReports::Dashboard::Families::EnteredClients',
        #   youth_families: 'GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies::EnteredClients',
      },
      housed: {
        #   veteran: 'GrdaWarehouse::WarehouseReports::Dashboard::Veteran::HousedClients',
        #   all_clients: 'GrdaWarehouse::WarehouseReports::Dashboard::AllClients::HousedClients',
        #   youth: 'GrdaWarehouse::WarehouseReports::Dashboard::Youth::HousedClients',
        #   non_veteran: 'GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::HousedClients',
        #   individual_adults: 'GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::HousedClients',
        #   parenting_children: 'GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::HousedClients',
        #   parenting_youth: 'GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::HousedClients',
        #   family_parents: 'GrdaWarehouse::WarehouseReports::Dashboard::Parents::HousedClients',
        #   children: 'GrdaWarehouse::WarehouseReports::Dashboard::Children::HousedClients',
        #   unaccompanied_minors: 'GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors::HousedClients',
        #   family: 'GrdaWarehouse::WarehouseReports::Dashboard::Families::HousedClients',
        #   youth_families: 'GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies::HousedClients',
      },
    }
  end

  def self.tabs
    Rails.application.config.sub_populations[:tabs] || {
      'census' => {
        title: 'Census',
        path: ['censuses'],
      },
      # 'clients' => {
      #   title: 'Client',
      #   path: ['dashboards_clients'],
      # },
      # 'individual_adults' => {
      #   title: 'Adults',
      #   path: ['dashboards_individual_adults'],
      # },
      # 'veteran' => {
      #   title: 'Veteran',
      #   path: ['dashboards_veterans'],
      # },
      # 'non_veteran' => {
      #   title: 'Non-Veteran',
      #   path: ['dashboards_non_veterans'],
      # },
      # 'family' => {
      #   title: 'Family',
      #   path: ['dashboards_families'],
      # },
      # 'youth_families' => {
      #   title: 'Youth Families',
      #   path: ['dashboards_youth_families'],
      # },
      # 'youths' => {
      #   title: 'Youth',
      #   path: ['dashboards_youths'],
      # },
      # 'family_parents' => {
      #   title: 'Parents',
      #   path: ['dashboards_family_parents'],
      # },
      # 'parenting_youth' => {
      #   title: 'Youth Parents',
      #   path: ['dashboards_parenting_youths'],
      # },
      # 'children_only' => {
      #   title: 'Children',
      #   path: ['dashboards_childrens'],
      # },
      # 'parenting_children' => {
      #   title: 'Juvenile Parents',
      #   path: ['dashboards_parenting_childrens'],
      # },
      # 'unaccompanied_minors' => {
      #   title: 'Unaccompanied Minors',
      #   path: ['dashboards_unaccompanied_minors'],
      # },
    }
  end

  def self.available_sub_populations
    Rails.application.config.sub_populations[:available] || {
      # 'All Clients' => :all_clients,
      # 'Veterans' => :veteran,
      # 'Youth' => :youth,
      # 'Family' => :family,
      # 'Youth Families' => :youth_families,
      # 'Children' => :children,
      # 'Parents' => :family_parents,
      # 'Parenting Youth' => :parenting_youth,
      # 'Parenting Juveniles' => :parenting_children,
      # 'Unaccompanied Minors' => :unaccompanied_minors,
      # 'Individual Adults' => :individual_adults,
      # 'Non-Veterans' => :non_veteran,
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
    types[:active][symbol] = "#{package}::ActiveClients"
    types[:entered][symbol] = "#{package}::EnteredClients"
    types[:housed][symbol] = "#{package}::HousedClients"
  end
end
