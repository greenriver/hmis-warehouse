# The core app (or other drivers) can check the presence of the
# YouthParentsSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:sub_pop_youth_parents)
#
# use with caution!
RailsDrivers.loaded << :youth_parents_sub_pop

GrdaWarehouse::WarehouseReports::Dashboard::Base.add_sub_population(
  'Youth Parents',
  :youth_parents,
  'YouthParentsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::YouthParents',
)

GrdaWarehouse::Census.add_population(
  population: :youth_parents,
  scope: GrdaWarehouse::ServiceHistoryEnrollment.youth_parents,
  factory: YouthParentsSubPop::GrdaWarehouse::Census::YouthParentsFactory,
)
