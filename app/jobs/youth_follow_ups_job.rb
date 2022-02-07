###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class YouthFollowUpsJob < BaseJob
  include NotifierConfig
  attr_accessor :send_notifications

  def initialize
    setup_notifier('YouthFollowUps')
    super
  end

  def perform
    @notifier.ping('Processing youth follow ups') if @send_notifications

    # Process all clients with a youth intake to update their follow up history for the last 90 days
    GrdaWarehouse::Youth::YouthFollowUp.recreate_follow_ups

    @notifier.ping('Updated youth follow ups') if @send_notifications
  end
end
