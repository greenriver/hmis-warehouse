###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  AvailableSubPopulations.add_sub_population(
    'All Clients',
    :clients,
    'ClientsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::Clients',
  )

  GrdaWarehouse::Census.add_population(
    population: :all_clients,
    factory: 'ClientsSubPop::GrdaWarehouse::Census::ClientsFactory',
  )

  SubpopulationHistoryScope.add_sub_population(
    :clients,
    :clients,
  )

  Reporting::MonthlyReports::Base.add_available_type(
    :clients,
    'ClientsSubPop::Reporting::MonthlyReports::Clients',
  )
end
