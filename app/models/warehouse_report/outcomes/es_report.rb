###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::Outcomes::EsReport < WarehouseReport::Outcomes::Base
  include ArelHelper

  def default_support_columns
    {
      residential_project: _('Project Name'),
      housed_date: _('Entry Date'),
      housing_exit: _('Exit Date'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: _('Project Name'),
      destination: _('Destination'),
      housed_date: _('Entry Date'),
      housing_exit: _('Exit Date'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: _('Exit Date'),
      return_date: _('Date of Return'),
      days_to_return: _('Days to Return'),
    }
  end

  def columns_for_destination
    {
      residential_project: _('Project Name'),
      destination: _('Destination'),
      housed_date: _('Entry Date'),
      housing_exit: _('Exit Date'),
    }
  end

  def housed_source
    Reporting::Housed.es
  end

  def project_types
    [1]
  end
end
