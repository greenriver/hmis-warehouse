###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class YouthFollowUpsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  include NotifierConfig
  attr_accessor :send_notifications

  def initialize
    setup_notifier('YouthFollowUps')
    super
  end

  def perform(...)
    instrument_as_maintenance_task do |run|
      _perform
      run.complete!
    end
  end

  def _perform
    @notifier.ping('Processing youth follow ups') if @send_notifications

    # Process all clients with a youth intake to update their follow up history for the last 90 days
    GrdaWarehouse::Youth::YouthFollowUp.recreate_follow_ups

    @notifier.ping('Updated youth follow ups') if @send_notifications
  end
end
