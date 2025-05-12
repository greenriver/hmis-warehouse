###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Update MCI Client from an Hmis::Hud::Client

module HmisExternalApis::AcHmis
  class UpdateMciClientJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

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

      client = Hmis::Hud::Client.find(client_id)

      mci = HmisExternalApis::AcHmis::Mci.new
      begin
        mci.update_client(client)
      rescue StandardError => e
        Sentry.capture_exception(e)
        Rails.logger.error("#{e.message} #{e.backtrace.join("\n")}")
      end
    end
  end
end
