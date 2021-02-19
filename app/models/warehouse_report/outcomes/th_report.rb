###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::Outcomes::ThReport < WarehouseReport::Outcomes::Base
  include ArelHelper

  def default_support_columns
    {
      residential_project: _('Project Name'),
      housed_date: _('Entry Date'),
      housing_exit: _('Exit Date'),
      project_id: _('Project ID'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: _('Project Name'),
      destination: _('Destination'),
      housed_date: _('Entry Date'),
      housing_exit: _('Exit Date'),
      project_id: _('Project ID'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: _('Exit Date'),
      return_date: _('Date of Return'),
      days_to_return: _('Days to Return'),
      project_id: _('Project ID'),
    }
  end

  def housed_source
    Reporting::Housed.th
  end

  def columns_for_destination
    {
      residential_project: _('Project Name'),
      destination: _('Destination'),
      housed_date: _('Entry Date'),
      housing_exit: _('Exit Date'),
      project_id: _('Project ID'),
    }
  end

  def project_types
    [2]
  end

  def self.available_subpopulations
    {
      youth: 'Youth (today)',
      youth_at_search_start: 'Youth (at entry)',
      veteran: 'Veteran',
    }.freeze
  end
end
