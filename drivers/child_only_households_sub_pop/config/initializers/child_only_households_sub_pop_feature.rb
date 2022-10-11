###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# ChildOnlyHouseholdsSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:child_only_households_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :child_only_households_sub_pop

Rails.application.reloader.to_prepare do
  AvailableSubPopulations.add_sub_population(
    'Child only Households',
    :child_only_households,
    'ChildOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::ChildOnlyHouseholds',
  )

  # GrdaWarehouse::Census.add_population(
  #   population: :child_only_households,
  #   scope: GrdaWarehouse::ServiceHistoryEnrollment.child_only_households,
  #   factory: ChildOnlyHouseholdsSubPop::GrdaWarehouse::Census::ChildOnlyHouseholdsFactory,
  # )

  SubpopulationHistoryScope.add_sub_population(
    :child_only_households,
    :child_only_households,
  )

  Reporting::MonthlyReports::Base.add_available_type(
    :child_only_households,
    'ChildOnlyHouseholdsSubPop::Reporting::MonthlyReports::ChildOnlyHouseholds',
  )
end
