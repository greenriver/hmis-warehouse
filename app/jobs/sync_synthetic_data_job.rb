###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SyncSyntheticDataJob < BaseJob
  include NotifierConfig
  attr_accessor :send_notifications
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def initialize
    setup_notifier('Synthetic Data')
    super
  end

  def perform
    return unless CasBase.db_exists?

    # Find CAS Non HMIS clients that should be connected to warehouse clients
    Cas::NonHmisClient.find_exact_matches
    GrdaWarehouse::Synthetic::Assessment.hud_sync
    GrdaWarehouse::Synthetic::Event.hud_sync
    GrdaWarehouse::Synthetic::YouthEducationStatus.hud_sync
  end
end
