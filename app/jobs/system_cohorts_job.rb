###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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

    @notifier.ping('Processing system cohorts') if @send_notifications

    GrdaWarehouse::SystemCohorts::Base.update_system_cohorts

    @notifier.ping('Processed system cohorts') if @send_notifications
  end
end
