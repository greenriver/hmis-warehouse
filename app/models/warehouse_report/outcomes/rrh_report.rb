###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::Outcomes::RrhReport < WarehouseReport::Outcomes::Base
  include ArelHelper

  def default_support_columns
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def columns_for_percent_exiting_pre_placement
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      housed_date: _('Date Housed'),
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
    }
  end

  def housed_source
    Reporting::Housed.rrh
  end

  def project_types
    [13]
  end
end
