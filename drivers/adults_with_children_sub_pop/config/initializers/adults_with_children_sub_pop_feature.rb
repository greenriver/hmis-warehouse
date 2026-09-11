###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
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
end
