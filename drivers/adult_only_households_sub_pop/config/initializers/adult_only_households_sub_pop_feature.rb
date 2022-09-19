###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# AdultOnlyHouseholdsSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:adult_only_households_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :adult_only_households_sub_pop
Rails.application.reloader.to_prepare do
  AvailableSubPopulations.add_sub_population(
    'Adult only Households',
    :adult_only_households,
    'AdultOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultOnlyHouseholds',
  )

  # GrdaWarehouse::Census.add_population(
  #   population: :adult_only_households,
  #   scope: GrdaWarehouse::ServiceHistoryEnrollment.adult_only_households,
  #   factory: AdultOnlyHouseholdsSubPop::GrdaWarehouse::Census::AdultOnlyHouseholdsFactory,
  # )

  SubpopulationHistoryScope.add_sub_population(
    :adult_only_households,
    :adult_only_households,
  )

  Reporting::MonthlyReports::Base.add_available_type(
    :adult_only_households,
    'AdultOnlyHouseholdsSubPop::Reporting::MonthlyReports::AdultOnlyHouseholds',
  )
end
