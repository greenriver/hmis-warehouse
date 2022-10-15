###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SystemCohortsJob < BaseJob
  include NotifierConfig
  attr_accessor :send_notifications
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def initialize
    setup_notifier('SystemCohorts')
    super
  end

  def perform
    return unless GrdaWarehouse::Config.get(:enable_system_cohorts)

    GrdaWarehouse::SystemCohorts::Base.update_all_system_cohorts
  end
end
