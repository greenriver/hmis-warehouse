###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

###
# This class interacts with the external AHA API to fetch client scores for Coordinated Entry.
# Scores are fetched by MCI Unique ID.
#
# For more details, see internal documentation:
#  https://docs.google.com/document/d/1Gcz9-t_utRcqGV9xCzQvTehjQOCqqPv_5-JY_IhhL4Q/
#
# Example Credential Setup:
# aha_cred = GrdaWarehouse::RemoteCredentials::ApiKey.where(slug: 'ac_hmis_aha').first_or_initialize
# aha_cred.attributes = {
#   username: '',
#   active: true,
#   base_url: 'https://<base url>',
#   authorization_header: 'Bearer <bearer token>',
#   additional_headers: {
#     'token': '<app token>',
#     'role': '<role public id>',
#   }
# }
# aha_cred.save!
#
#
# Investigating logs:
#  HmisExternalApis::ExternalRequestLog.outgoing.url_like("scores").failed.where(requested_at: 3.days.ago..).count
###
module HmisExternalApis::AcHmis
  class Aha
    SYSTEM_ID = 'ac_hmis_aha'
    AHA_GENERATOR = 'AHA'
    VALID_AHA_SCORES = [-1, *(1..10)].freeze # AHA can be -1 or 1..10, but not zero. (Note that 'MH-AHA' generator appears to support zero as a score.)
    CONNECTION_TIMEOUT_SECONDS = Rails.env.staging? ? 10 : 5

    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to AHA')
    NoMciUniqueIdError = HmisErrors::ApiError.new(display_message: 'Client does not have an MCI unique ID')

    def fetch_score(client)
      # Collect MCI unique IDs for this client and all source clients with the same destination client
      clients = [client, *client.destination_client&.source_clients&.to_a]
      mci_uniq_ids = clients.compact.uniq.filter_map do |c|
        c.ac_hmis_mci_unique_id&.value
      end.uniq

      raise NoMciUniqueIdError if mci_uniq_ids.empty?

      payload = if mci_uniq_ids.size > 1
        { 'dw_client_id__dw_client_id__overlap': mci_uniq_ids.join(',') }
      else
        { 'dw_client_id__dw_client_id__includes': mci_uniq_ids.first }
      end

      result = conn.post('api/v1/clients/scores/search/', payload).
        then { |r| handle_error(r) }

      data = result.parsed_body&.dig('data')
      raise(Error, "AHA response missing `data` key. Response body: `#{result.parsed_body}`") unless data

      score_objects = data.flat_map do |response_client|
        response_client.dig('scores')&.filter_map do |score_obj|
          score_value = score_obj.dig('score')
          next unless score_obj.dig('generator') == AHA_GENERATOR # non-AHA scores

          raise(Error, 'Received blank score') if score_value.blank?
          raise(Error, "Received invalid score: #{score_value.inspect}") unless score_value.is_a?(Numeric) && score_value % 1 == 0 && VALID_AHA_SCORES.include?(score_value.to_i)

          OpenStruct.new(
            # AHA Score
            score: score_value.to_i,
            # This field is a 0/1 flag indicating whether the Alt-AHA should be performed or not. (1 = Alt-AHA is required, 0 = Alt-AHA is not required).
            mci_quality_indicator: score_obj.dig('metadata', 'alt_aha_flag')&.to_i,
            # MCI Unique ID that is associated with the AHA score
            dw_client_id: Array.wrap(response_client.dig('dw_client_id') || response_client.dig('dw_client_id_dw_client_id'))&.first,
            # Generator is always 'AHA'
            generator: score_obj.dig('generator'),
          )
        end
      end

      # Find the highest AHA score
      highest_aha_score = score_objects.compact.max_by(&:score)

      raise(Error, 'Response does not contain AHA score') unless highest_aha_score.present?

      highest_aha_score
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
