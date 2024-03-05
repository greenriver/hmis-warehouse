###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::Outcomes::EsReport < WarehouseReport::Outcomes::Base
  include ArelHelper

  def title
    'Emergency Shelter Dashboard'
  end

  def clients_path_array
    [
      :clients,
      :warehouse_reports,
      :shelter,
      :index,
    ]
  end

  def default_support_columns
    {
      residential_project: Translation.translate('Project Name'),
      housed_date: Translation.translate('Entry Date'),
      housing_exit: Translation.translate('Exit Date'),
      project_id: Translation.translate('Warehouse Project ID'),
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: Translation.translate('Project Name'),
      destination: Translation.translate('Destination'),
      housed_date: Translation.translate('Entry Date'),
      housing_exit: Translation.translate('Exit Date'),
      project_id: Translation.translate('Warehouse Project ID'),
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: Translation.translate('Exit Date'),
      return_date: Translation.translate('Date of Return'),
      days_to_return: Translation.translate('Days to Return'),
      destination: Translation.translate('Destination'),
      race: Translation.translate('Race'),
    }
  end

  def columns_for_destination
    {
      residential_project: Translation.translate('Project Name'),
      destination: Translation.translate('Destination'),
      housed_date: Translation.translate('Entry Date'),
      housing_exit: Translation.translate('Exit Date'),
      project_id: Translation.translate('Warehouse Project ID'),
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
    }
  end

  def housed_source
    Reporting::Housed.es
  end

  def project_types
    HudUtility2024.performance_reporting[:es]
  end

  def self.available_subpopulations
    {
      youth: 'Youth (today)',
      youth_at_search_start: 'Youth (at entry)',
      veteran: 'Veteran',
    }.freeze
  end
end
