###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2022::StatusProgressionConcern
  extend ActiveSupport::Concern

  def start_report
    self.update( # rubocop:disable Style/RedundantSelf:
      started_at: Time.current,
      percent_complete: 0.01,
      state: 'Started',
    )
  end

  def log_and_ping msg
    msg = "#{msg} (LSA FY2022 Report: #{id}, percent_complete: #{percent_complete}) #{Time.current}"
    Rails.logger.info msg
    @notifier.ping(msg) if @send_notifications
  end

  def finish_report
    self.update( # rubocop:disable Style/RedundantSelf:
      percent_complete: 100,
      completed_at: Time.now,
    )
  end
end
