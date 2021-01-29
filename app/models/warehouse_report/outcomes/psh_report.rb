###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::Outcomes::PshReport < WarehouseReport::Outcomes::Base
  include ArelHelper

  def default_support_columns
    {
      service_project: _('Housing Search'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def columns_for_percent_exiting_pre_placement
    {
      service_project: _('Housing Search'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      housed_date: _('Date Housed'),
    }
  end

  def columns_for_percent_in_stabilization
    {
      service_project: _('Housing Search'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: _('Housing Exit'),
      return_date: _('Date of Return'),
      days_to_return: _('Days to Return'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: _('Stabilization Project'),
      destination: _('Destination'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def columns_for_destination
    {
      residential_project: _('Stabilization Project'),
      destination: _('Destination'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def housed_source
    Reporting::Housed.psh
  end

  def project_types
    [3, 9, 10]
  end
end
