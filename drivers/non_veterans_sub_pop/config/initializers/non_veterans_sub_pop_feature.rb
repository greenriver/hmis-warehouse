###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  AvailableSubPopulations.add_sub_population(
    'Non-Veteran',
    :non_veterans,
    'NonVeteransSubPop::GrdaWarehouse::WarehouseReports::Dashboard::NonVeterans',
  )

  GrdaWarehouse::Census.add_population(
    population: :non_veterans,
    factory: 'NonVeteransSubPop::GrdaWarehouse::Census::NonVeteransFactory',
  )

  SubpopulationHistoryScope.add_sub_population(
    :non_veterans,
    :non_veterans,
  )

  Reporting::MonthlyReports::Base.add_available_type(
    :non_veterans,
    'NonVeteransSubPop::Reporting::MonthlyReports::NonVeterans',
  )
end
