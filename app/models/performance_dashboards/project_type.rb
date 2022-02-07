###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::ProjectType < PerformanceDashboards::Base
  include PerformanceDashboard::ProjectType::LivingSituation
  include PerformanceDashboard::ProjectType::Destination
  include PerformanceDashboard::ProjectType::LengthOfTime
  include PerformanceDashboard::ProjectType::Returns
  include PerformanceDashboard::ProjectType::Detail
  include PerformanceDashboard::Overview::Entering

  def self.url
    'performance_dashboards/project_type'
  end

  def project_type_title
    GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES[filter.project_type_codes.first&.to_sym]
  end

  def multiple_project_types?
    false
  end

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
  end

  def section_subpath
    'performance_dashboards/project_type/'
  end

  def self.available_chart_types
    [
      'prior_living_situations',
      'destinations',
      'lengths_of_time',
      'returns',
    ]
  end

  def available_breakdowns
    {}
  end

  def report_path_array
    [
      :performance,
      :dashboards,
      :project_type,
      :index,
    ]
  end
end
