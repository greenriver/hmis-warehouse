###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# AdultsWithChildrenTwentyfivePlusHohSubPop driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:adults_with_children_twentyfive_plus_hoh_sub_pop)
#
# use with caution!
RailsDrivers.loaded << :adults_with_children_twentyfive_plus_hoh_sub_pop
Rails.application.reloader.to_prepare do
  AvailableSubPopulations.add_sub_population(
    'Adult and Child Households With HoH 25+',
    :adults_with_children_twentyfive_plus_hoh,
    'AdultsWithChildrenTwentyfivePlusHohSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildrenTwentyfivePlusHoh',
  )

  # GrdaWarehouse::Census.add_population(
  #   population: :adults_with_children_twentyfive_plus_hoh,
  #   scope: GrdaWarehouse::ServiceHistoryEnrollment.adults_with_children_twentyfive_plus_hoh,
  #   factory: AdultsWithChildrenTwentyfivePlusHohSubPop::GrdaWarehouse::Census::AdultsWithChildrenTwentyfivePlusHohFactory,
  # )

  SubpopulationHistoryScope.add_sub_population(
    :adults_with_children_twentyfive_plus_hoh,
    :adults_with_children_twentyfive_plus_hoh,
  )

  # Reporting::MonthlyReports::Base.add_available_type(
  #   :adults_with_children_twentyfive_plus_hoh,
  #   'AdultsWithChildrenTwentyfivePlusHohSubPop::Reporting::MonthlyReports::AdultsWithChildrenTwentyfivePlusHoh',
  # )
end
