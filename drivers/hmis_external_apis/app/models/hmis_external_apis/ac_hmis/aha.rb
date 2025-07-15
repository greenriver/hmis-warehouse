###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class Aha
    SYSTEM_ID = 'ac_hmis_aha'
    CONNECTION_TIMEOUT_SECONDS = Rails.env.staging? ? 10 : 5

    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to AHA')

    def fetch_score(client)
      mci_ids = client.ac_hmis_mci_ids.map(&:value)
      return nil if mci_ids.empty?

      payload = {
        'mc_id__in': mci_ids,
      }

      result = conn.post('api/v1/clients/scores', payload).
        then { |r| handle_error(r) }

      # 404 indicates client was not found
      return nil if result.http_status == 404

      # Find and return highest score
      scores = result.parsed_body&.dig('data')&.map { |c| c.dig('score') } || []
      scores.compact_blank!

      # Validate that all scores are numerical
      non_numerical_scores = scores.reject { |score| score.is_a?(Numeric) }
      raise(Error, "Received non-numerical scores: #{non_numerical_scores.inspect}") if non_numerical_scores.any?

      highest_score = scores.uniq.max
      return nil if highest_score&.negative?

      highest_score
    end

    def self.enabled?
      ::GrdaWarehouse::RemoteCredentials::ApiKey.active.where(slug: SYSTEM_ID).exists?
    end

    private

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredentials::ApiKey.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||= HmisExternalApis::ApiKeyConnection.new(creds, connection_timeout: CONNECTION_TIMEOUT_SECONDS)
    end

    def handle_error(result)
      Rails.logger.error "AHA Error: #{result.error}" if result.error
      raise(Error, result.error) if result.error

      result
    end
  end
end
