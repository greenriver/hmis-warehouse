###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  AvailableSubPopulations.add_sub_population(
    'Veterans',
    :veterans,
    'VeteransSubPop::GrdaWarehouse::WarehouseReports::Dashboard::Veterans',
  )

  GrdaWarehouse::Census.add_population(
    population: :veterans,
    factory: 'VeteransSubPop::GrdaWarehouse::Census::VeteransFactory',
  )

  SubpopulationHistoryScope.add_sub_population(
    :veterans,
    :veterans,
  )

  Reporting::MonthlyReports::Base.add_available_type(
    :veterans,
    'VeteransSubPop::Reporting::MonthlyReports::Veterans',
  )
end
