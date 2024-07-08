###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Update MCI Client from an Hmis::Hud::Client

module HmisExternalApis::AcHmis
  class UpdateMciClientJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
    include NotifierConfig

    MCI_CLIENT_COLS = [
      'FirstName',
      'LastName',
      'MiddleName',
      'DOB',
      'SSN',
      'Gender',
      'GenderNone',
      'GenderOther',
    ].freeze

    # @param clent_id [Integer] Hmis::Hud::Client ID
    def perform(client_id:)
      return unless HmisExternalApis::AcHmis::Mci.enabled?

      setup_notifier('UpdateMciClientJob')

      client = Hmis::Hud::Client.find(client_id)

      mci = HmisExternalApis::AcHmis::Mci.new
      begin
        mci.update_client(client)
      rescue StandardError => e
        @notifier.ping('Failure in MCI Update Client job', { exception: e })
      end
    end
  end
end
