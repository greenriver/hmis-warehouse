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
      mci_uniq_id = client.ac_hmis_mci_unique_id
      return nil unless mci_uniq_id.present?

      payload = {
        'dw_client_id': mci_uniq_id.value.to_s,
      }

      result = conn.post('api/v1/clients/scores/search/', payload).
        then { |r| handle_error(r) }

      data = result.parsed_body&.dig('data')
      raise(Error, "AHA response missing `data` key. Response body: `#{result.parsed_body}`") unless data

      score_objects = data.flat_map do |response_client|
        response_client.dig('scores')&.filter_map do |score_obj|
          score_value = score_obj.dig('score')

          raise(Error, 'Received blank score') if score_value.blank?
          raise(Error, "Received invalid score: #{score_value.inspect}") unless score_value.is_a?(Numeric) && score_value % 1 == 0 && score_value <= 10

          OpenStruct.new(
            score: score_value.to_i,
            alt_aha_flag: score_obj.dig('metadata', 'alt_aha_flag')&.to_i == 1,
            dw_client_id: response_client.dig('dw_client_id'),
            generator: score_obj.dig('generator'),
          )
        end
      end

      highest_score_object = score_objects.compact.max_by(&:score)
      return nil if highest_score_object.nil? || highest_score_object.score&.negative?

      highest_score_object
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
      if result.error
        Rails.logger.error "AHA API Error: #{result.error}"
        raise(Error, result.error)
      end

      # Check if HTTP status indicates success (200-299 range)
      return result if http_status_successful?(result.http_status)

      # Handle specific case: 404 with "No client found" shouldn't raise, just return no ID
      return result if client_not_found_response?(result)

      raise(Error, "AHA HTTP error: Received non-200 HTTP status: #{result.http_status}")
    end

    def http_status_successful?(status)
      status.in?(200..299)
    end

    def client_not_found_response?(result)
      result.http_status == 404 && result.parsed_body&.dig('message') == 'No client found.'
    end
  end
end
