###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PerformanceDashboards::ProjectType < PerformanceDashboards::Base # rubocop:disable Style/ClassAndModuleChildren
  include PerformanceDashboard::ProjectType::LivingSituation
  include PerformanceDashboard::ProjectType::Destination
  include PerformanceDashboard::ProjectType::LengthOfTime
  include PerformanceDashboard::ProjectType::Returns
  include PerformanceDashboard::ProjectType::Detail

  def project_type_title
    GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES[filter.project_type_codes.first&.to_sym]
  end

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
  end

  def self.available_chart_types
    [
      'living_situations',
      'destinations',
      'lengths_of_time',
      'returns',
    ]
  end
end
