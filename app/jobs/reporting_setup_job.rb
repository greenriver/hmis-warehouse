###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportingSetupJob < BaseJob
  include ActionView::Helpers::DateHelper
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def start_message; 'Reporting database updating' end

  def done_message(t); "Reporting database updated in #{t}" end

  def perform
    Reporting::Housed.new.populate!
    log_progress('Housed done, starting Return')
    Reporting::Return.new.populate!
  end

  def max_attempts
    1
  end
end
