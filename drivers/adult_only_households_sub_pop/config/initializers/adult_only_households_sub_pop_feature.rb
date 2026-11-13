###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
