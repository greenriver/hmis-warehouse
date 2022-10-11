###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# ClientsSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:clients_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :clients_sub_pop

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
