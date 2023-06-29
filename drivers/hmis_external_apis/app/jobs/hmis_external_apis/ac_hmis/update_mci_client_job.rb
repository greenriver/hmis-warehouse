###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Update MCI Client from an Hmis::Hud::Client

module HmisExternalApis::AcHmis
  class UpdateMciClientJob < ApplicationJob
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
      mci.update_client(client)
    end
  end
end
