###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::Outcomes::RrhReport < WarehouseReport::Outcomes::Base
  include ArelHelper

  def title
    'Rapid Rehousing Dashboard'
  end

  def clients_path_array
    [
      :clients,
      :warehouse_reports,
      :rrh,
      :index,
    ]
  end

  def default_support_columns
    {
      service_project: Translation.translate('Pre-Placement Project'),
      search_start: Translation.translate('Search Start'),
      search_end: Translation.translate('Search End'),
      residential_project: Translation.translate('Stabilization Project'),
      housed_date: Translation.translate('Date Housed'),
      housing_exit: Translation.translate('Housing Exit'),
      project_id: "Warehouse #{Translation.translate('Stabilization Project')} ID",
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
      ethnicity: Translation.translate('Ethnicity'),
      gender: Translation.translate('Gender'),
    }
  end

  def columns_for_percent_exiting_pre_placement
    {
      service_project: Translation.translate('Pre-Placement Project'),
      search_start: Translation.translate('Search Start'),
      search_end: Translation.translate('Search End'),
      housed_date: Translation.translate('Date Housed'),
      race: Translation.translate('Race'),
      ethnicity: Translation.translate('Ethnicity'),
      gender: Translation.translate('Gender'),
    }
  end

  def columns_for_percent_in_stabilization
    {
      service_project: Translation.translate('Pre-Placement Project'),
      search_start: Translation.translate('Search Start'),
      search_end: Translation.translate('Search End'),
      residential_project: Translation.translate('Stabilization Project'),
      housed_date: Translation.translate('Date Housed'),
      housing_exit: Translation.translate('Housing Exit'),
      project_id: "Warehouse #{Translation.translate('Stabilization Project')} ID",
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
      ethnicity: Translation.translate('Ethnicity'),
      gender: Translation.translate('Gender'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: Translation.translate('Housing Exit'),
      return_date: Translation.translate('Date of Return'),
      days_to_return: Translation.translate('Days to Return'),
      destination: Translation.translate('Destination'),
      race: Translation.translate('Race'),
      ethnicity: Translation.translate('Ethnicity'),
      gender: Translation.translate('Gender'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: Translation.translate('Stabilization Project'),
      destination: Translation.translate('Destination'),
      housed_date: Translation.translate('Date Housed'),
      housing_exit: Translation.translate('Housing Exit'),
      project_id: "Warehouse #{Translation.translate('Stabilization Project')} ID",
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
      ethnicity: Translation.translate('Ethnicity'),
      gender: Translation.translate('Gender'),
    }
  end

  def columns_for_destination
    {
      residential_project: Translation.translate('Stabilization Project'),
      destination: Translation.translate('Destination'),
      housed_date: Translation.translate('Date Housed'),
      housing_exit: Translation.translate('Housing Exit'),
      project_id: "Warehouse #{Translation.translate('Stabilization Project')} ID",
      hmis_project_id: Translation.translate('HMIS Project ID'),
      race: Translation.translate('Race'),
      ethnicity: Translation.translate('Ethnicity'),
      gender: Translation.translate('Gender'),
    }
  end

  def housed_source
    Reporting::Housed.rrh
  end

  def project_types
    [13]
  end
end
