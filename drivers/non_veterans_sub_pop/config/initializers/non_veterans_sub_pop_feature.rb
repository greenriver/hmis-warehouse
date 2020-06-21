# The core app (or other drivers) can check the presence of the
# NonVeteransSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:non_veterans_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :non_veterans_sub_pop

AvailableSubPopulations.add_sub_population(
  'Non-Veteran',
  :non_veterans,
  'NonVeteransSubPop::GrdaWarehouse::WarehouseReports::Dashboard::NonVeterans',
)

GrdaWarehouse::Census.add_population(
  population: :non_veterans,
  scope: GrdaWarehouse::ServiceHistoryEnrollment.non_veterans,
  factory: NonVeteransSubPop::GrdaWarehouse::Census::NonVeteransFactory,
)

SubpopulationHistoryScope.add_sub_population(
  :non_veterans,
  :non_veterans,
)

Reporting::MonthlyReports::Base.add_available_type(
  :non_veterans,
  'NonVeteransSubPop::Reporting::MonthlyReports::NonVeterans',
)