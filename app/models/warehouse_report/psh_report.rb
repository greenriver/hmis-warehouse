###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::PshReport < WarehouseReport::RrhReport
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

  def housed_source
    Reporting::Housed.psh
  end
end