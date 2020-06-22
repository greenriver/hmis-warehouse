# The core app (or other drivers) can check the presence of the
# ClientsSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:clients_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :clients_sub_pop

AvailableSubPopulations.add_sub_population(
  'All Clients',
  :clients,
  'ClientsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::Clients',
)

GrdaWarehouse::Census.add_population(
  population: :all_clients,
  scope: GrdaWarehouse::ServiceHistoryEnrollment.clients,
  factory: ClientsSubPop::GrdaWarehouse::Census::ClientsFactory,
)

SubpopulationHistoryScope.add_sub_population(
  :clients,
  :clients,
)

Reporting::MonthlyReports::Base.add_available_type(
  :clients,
  'ClientsSubPop::Reporting::MonthlyReports::Clients',
)