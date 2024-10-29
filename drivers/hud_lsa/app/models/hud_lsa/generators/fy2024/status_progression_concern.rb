###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2024::StatusProgressionConcern
  extend ActiveSupport::Concern

  def start_report
    self.update( # rubocop:disable Style/RedundantSelf:
      started_at: Time.current,
      percent_complete: 0.01,
      state: 'Started',
    )
  end

  def log_and_ping msg
    msg = "#{msg} (LSA FY2024 Report: #{id}, percent_complete: #{percent_complete}) #{Time.current}"
    Rails.logger.info msg
    @notifier.ping(msg) if @send_notifications
  end

  def finish_report
    self.update( # rubocop:disable Style/RedundantSelf:
      percent_complete: 100,
      completed_at: Time.now,
      remaining_questions: [],
      state: 'Completed',
    )
  end

  def fail_report(reason = nil)
    self.update( # rubocop:disable Style/RedundantSelf:
      percent_complete: 0,
      failed_at: Time.now,
      remaining_questions: [],
      state: 'Failed',
      error_details: reason,
    )
  end
end
