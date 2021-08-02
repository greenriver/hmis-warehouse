###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
      project_id: "Warehouse #{_('Stabilization Project')} ID",
      hmis_project_id: _('HMIS Project ID'),
      race: _('Race'),
      ethnicity: _('Ethnicity'),
      gender: _('Gender'),
    }
  end

  def columns_for_percent_exiting_pre_placement
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      housed_date: _('Date Housed'),
      race: _('Race'),
      ethnicity: _('Ethnicity'),
      gender: _('Gender'),
    }
  end

  def columns_for_percent_in_stabilization
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
      project_id: "Warehouse #{_('Stabilization Project')} ID",
      hmis_project_id: _('HMIS Project ID'),
      race: _('Race'),
      ethnicity: _('Ethnicity'),
      gender: _('Gender'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: _('Housing Exit'),
      return_date: _('Date of Return'),
      days_to_return: _('Days to Return'),
      destination: _('Destination'),
      race: _('Race'),
      ethnicity: _('Ethnicity'),
      gender: _('Gender'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: _('Stabilization Project'),
      destination: _('Destination'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
      project_id: "Warehouse #{_('Stabilization Project')} ID",
      hmis_project_id: _('HMIS Project ID'),
      race: _('Race'),
      ethnicity: _('Ethnicity'),
      gender: _('Gender'),
    }
  end

  def columns_for_destination
    {
      residential_project: _('Stabilization Project'),
      destination: _('Destination'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
      project_id: "Warehouse #{_('Stabilization Project')} ID",
      hmis_project_id: _('HMIS Project ID'),
      race: _('Race'),
      ethnicity: _('Ethnicity'),
      gender: _('Gender'),
    }
  end

  def housed_source
    Reporting::Housed.rrh
  end

  def project_types
    [13]
  end
end
