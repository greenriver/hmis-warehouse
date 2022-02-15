###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# AdultsWithChildrenSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:adults_with_children_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :adults_with_children_sub_pop

AvailableSubPopulations.add_sub_population(
  'Adult and Child Households',
  :adults_with_children,
  'AdultsWithChildrenSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildren',
)

# GrdaWarehouse::Census.add_population(
#   population: :adults_with_children,
#   scope: GrdaWarehouse::ServiceHistoryEnrollment.adults_with_children,
#   factory: AdultsWithChildrenSubPop::GrdaWarehouse::Census::AdultsWithChildrenFactory,
# )

SubpopulationHistoryScope.add_sub_population(
  :adults_with_children,
  :adults_with_children,
)

Reporting::MonthlyReports::Base.add_available_type(
  :adults_with_children,
  'AdultsWithChildrenSubPop::Reporting::MonthlyReports::AdultsWithChildren',
)
