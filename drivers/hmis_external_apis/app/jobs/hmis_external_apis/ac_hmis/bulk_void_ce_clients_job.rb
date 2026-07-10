###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisExternalApis::AcHmis::BulkVoidCeClientsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform(destination_client_ids:, initiated_by_id:)
    HmisExternalApis::AcHmis::BulkVoider.new.perform(
      destination_client_ids: destination_client_ids,
      initiated_by_id: initiated_by_id,
    )
  end
end
