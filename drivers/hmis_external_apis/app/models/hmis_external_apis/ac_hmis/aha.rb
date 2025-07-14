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
      mci_ids = client.ac_hmis_mci_ids.map(&:value)
      return nil if mci_ids.empty?

      payload = {
        'mc_id__in': mci_ids,
      }

      result = conn.post('api/v1/clients/scores', payload).
        then { |r| handle_error(r) }

      return nil if result.http_status == 404

      # Find and return highest score
      scores = result.parsed_body&.dig('data')&.map { |c| c.dig('score') } || []

      # Validate that all scores are numerical
      non_numerical_scores = scores.compact.reject { |score| score.is_a?(Numeric) }
      raise(Error, "Received non-numerical scores: #{non_numerical_scores.inspect}") if non_numerical_scores.any?

      highest_score = scores.compact.uniq.max
      highest_score == -999 ? nil : highest_score # Special case for -999, which indicates no data
    end

    def self.enabled?
      # Both MCI and AHA credentials need to exist for AHA api to be enabled, since we query the API by MCI ID.
      aha_cred = ::GrdaWarehouse::RemoteCredentials::ApiKey.active.where(slug: SYSTEM_ID)
      mci_cred = ::GrdaWarehouse::RemoteCredentials::Oauth.active.where(slug: HmisExternalApis::AcHmis::Mci::SYSTEM_ID)
      aha_cred.exists? && mci_cred.exists?
    end

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
