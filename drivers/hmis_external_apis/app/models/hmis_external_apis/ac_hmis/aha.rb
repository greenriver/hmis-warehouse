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
        'dw_client_id': mci_ids.join(','),
      }

      result = conn.post('api/v1/clients/scores/search/', payload).
        then { |r| handle_error(r) }

      # 404 indicates client was not found # todo @martha - if client not found
      return nil if result.http_status == 404

      score_objects = result.parsed_body&.dig('data')&.flat_map do |response_client|
        response_client.dig('scores')&.filter_map do |score_obj|
          score_value = score_obj.dig('score')

          raise(Error, 'Received blank score') if score_value.blank?
          raise(Error, "Received invalid score: #{score_value.inspect}") unless score_value.is_a?(Numeric) && score_value % 1 == 0 && score_value <= 10

          OpenStruct.new(
            score: score_value.to_i,
            alt_aha_flag: score_obj.dig('metadata', 'alt_aha_flag'),
          )
        end || []
      end || []

      highest_score_object = score_objects.max_by(&:score)
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
      Rails.logger.error "AHA Error: #{result.error}" if result.error
      raise(Error, result.error) if result.error

      result
    end
  end
end
