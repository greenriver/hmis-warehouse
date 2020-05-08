###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::ProjectType < PerformanceDashboards::Base # rubocop:disable Style/ClassAndModuleChildren
  include PerformanceDashboard::ProjectType::LivingSituation
  include PerformanceDashboard::ProjectType::Destination
  include PerformanceDashboard::ProjectType::LengthOfTime
  include PerformanceDashboard::ProjectType::Detail

  def self.available_keys
    {
      entering: :entering,
      exiting: :exiting,
    }
  end
end
