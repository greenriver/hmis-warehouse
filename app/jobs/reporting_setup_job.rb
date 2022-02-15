###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportingSetupJob < BaseJob
  include ActionView::Helpers::DateHelper
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform
    setup_notifier('ReportingSetupJob')
    started_at = Time.current
    @notifier.ping('Reporting database updating') if @send_notifications
    Reporting::Housed.new.populate!
    elapsed = distance_of_time_in_words(started_at, Time.current)
    @notifier.ping("Reporting database Housed completed in #{elapsed}, starting Return") if @send_notifications
    Reporting::Return.new.populate!
    elapsed = distance_of_time_in_words(started_at, Time.current)
    @notifier.ping("Reporting database updated in #{elapsed}") if @send_notifications
  end

  def max_attempts
    1
  end
end
