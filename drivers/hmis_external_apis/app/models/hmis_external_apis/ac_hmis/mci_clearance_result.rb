###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  MciClearanceResult = Struct.new(
    :mci_id,
    :score, # Match score
    :client, # Unpersisted Client containing all the identifying information we got from MCI
    :existing_client_id, # ID of Hmis::Hud::Client that already exists with this MCI ID
    keyword_init: true,
  ) do
  end
end
