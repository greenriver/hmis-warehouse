###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SyncSyntheticDataJob < BaseJob
  include NotifierConfig
  attr_accessor :send_notifications

  def initialize
    setup_notifier('Synthetic Data')
    super
  end

  def perform
    @notifier.ping('Processing synthetic data') if @send_notifications

    GrdaWarehouse::Synthetic::Event.hud_sync
    GrdaWarehouse::Synthetic::Assessment.hud_sync

    @notifier.ping('Updated synthetic data') if @send_notifications
  end
end
