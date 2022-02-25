###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# AdultsWithChildrenYouthHohSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:adults_with_children_youth_hoh_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :adults_with_children_youth_hoh_sub_pop

AvailableSubPopulations.add_sub_population(
  'Adult and Child Households With HoH 18-24',
  :adults_with_children_youth_hoh,
  'AdultsWithChildrenYouthHohSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildrenYouthHoh',
)

# GrdaWarehouse::Census.add_population(
#   population: :adults_with_children_youth_hoh,
#   scope: GrdaWarehouse::ServiceHistoryEnrollment.adults_with_children_youth_hoh,
#   factory: AdultsWithChildrenYouthHohSubPop::GrdaWarehouse::Census::AdultsWithChildrenYouthHohFactory,
# )

SubpopulationHistoryScope.add_sub_population(
  :adults_with_children_youth_hoh,
  :adults_with_children_youth_hoh,
)

Reporting::MonthlyReports::Base.add_available_type(
  :adults_with_children_youth_hoh,
  'AdultsWithChildrenYouthHohSubPop::Reporting::MonthlyReports::AdultsWithChildrenYouthHoh',
)
