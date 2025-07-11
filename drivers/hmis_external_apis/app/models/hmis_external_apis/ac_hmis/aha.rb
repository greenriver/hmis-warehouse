###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class Aha
    SYSTEM_ID = 'ac_hmis_aha'

    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to AHA')

    def fetch_score(client)
      mci_id = client.ac_hmis_mci_ids.first&.value # todo @martha - what if there are multiple MCI IDs? what if none?

      payload = {
        'mc_id__eq': mci_id,
      }

      # todo @Martha - rack app that can locally mimic external api?
      result = conn.post('api/v1/clients/scores', payload).
        then { |r| handle_error(r) }

      # todo @martha - what if multiple clients are returned?
      # todo @martha - special case if score is -999
      result.parsed_body.first&.dig('score') if result.parsed_body.is_a?(Array)
      # todo @martha - this should probably have responded with "Failed to connect to AHA"
      ''
    end

    # todo @martha - MCI ID AND AHA are both required
    # def self.enabled?
    #   ::GrdaWarehouse::RemoteCredentials::Oauth.active.where(slug: SYSTEM_ID).exists?
    # end

    private

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredentials::ApiKey.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||= HmisExternalApis::ApiKeyConnection.new(creds)
    end

    def handle_error(result)
      Rails.logger.error "AHA Error: #{result.error}" if result.error
      Sentry.capture_exception(StandardError.new(result.error)) if result.error
      raise(Error, result.error) if result.error

      result
    end
  end
end
