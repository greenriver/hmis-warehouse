###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportingSetupJob < BaseJob
  def perform
    setup_notifier('ReportingSetupJob')
    @notifier.ping('Reporting database updating') if @send_notifications
    Reporting::Housed.new.populate!
    Reporting::Return.new.populate!
    @notifier.ping('Reporting database updated') if @send_notifications
  end

  def max_attempts
    1
  end
end
