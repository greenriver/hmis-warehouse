###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
