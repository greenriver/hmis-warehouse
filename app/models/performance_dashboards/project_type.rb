###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::ProjectType < PerformanceDashboards::Base # rubocop:disable Style/ClassAndModuleChildren
  include PerformanceDashboard::ProjectType::LivingSituation
  include PerformanceDashboard::ProjectType::Detail
  # include PerformanceDashboard::ProjectType::Age
  # include PerformanceDashboard::Overview::Gender
  # include PerformanceDashboard::Overview::Household
  # include PerformanceDashboard::Overview::Veteran
  # include PerformanceDashboard::Overview::Race
  # include PerformanceDashboard::Overview::Ethnicity

  # include PerformanceDashboard::Overview::Exiting
  # include PerformanceDashboard::Overview::Enrolled

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
  end
end
