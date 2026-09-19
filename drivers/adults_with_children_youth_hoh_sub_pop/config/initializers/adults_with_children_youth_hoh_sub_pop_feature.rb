###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
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
end
