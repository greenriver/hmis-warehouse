###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class RunEtoApiUpdateForClientJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    def perform(destination_id:, client_ids:)
      return unless requires_api_update?(destination_id)

      EtoApi::Tasks::UpdateClientDemographics.new(
        client_ids: client_ids,
        run_time: 5.minutes,
        one_off: true,
      ).run!
    end

    before_enqueue do |job|
      client = fetch_destination_client(job)
      client.update(api_update_in_process: true, api_update_started_at: Time.now)
    end

    after_perform do |job|
      client = fetch_destination_client(job)
      client.update(api_update_in_process: false, api_last_updated_at: Time.now)
    end

    def fetch_destination_client(job)
      destination_id = job.arguments.first[:destination_id]
      GrdaWarehouse::Hud::Client.find(destination_id)
    end

    # don't allow someone to queue a refresh if it's been less than 30 minutes
    def requires_api_update?(destination_id)
      client = GrdaWarehouse::Hud::Client.find(destination_id)
      client.requires_api_update?(check_period: 30.minutes)
    end
  end
end
