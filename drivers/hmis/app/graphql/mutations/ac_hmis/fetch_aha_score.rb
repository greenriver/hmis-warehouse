###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AcHmis::FetchAhaScore < CleanBaseMutation
    description 'Return AHA score for client'

    AhaFailedReason = Types::BaseEnum.build('AhaFailedReason') do
      value 'NO_MCI_UNIQUE_ID', 'Client does not have an MCI unique ID'
    end

    argument :client_id, ID, required: true
    argument :lookup_catalyst, String, required: false
    argument :lookup_reason, [String], required: false

    field :score, Integer, null: true
    field :mh_score, Integer, null: true
    field :mci_quality_indicator, Integer, null: true
    field :dw_client_id, String, null: true
    field :generator, String, null: true
    field :aha_failed_reason, AhaFailedReason, null: true

    def resolve(client_id:, lookup_catalyst: nil, lookup_reason: nil)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: 'AHA connection is not configured' unless HmisExternalApis::AcHmis::Aha.enabled?
      return { errors: errors } if errors.any?

      # If you have permission to view this client, you can fetch their AHA score
      client = Hmis::Hud::Client.viewable_by(current_user).find_by(id: client_id)
      access_denied! unless client.present?

      aha = HmisExternalApis::AcHmis::Aha.new
      begin
        result = aha.fetch_score(
          client,
          lookup_catalyst: lookup_catalyst,
          lookup_reason: lookup_reason,
          requested_generators: [:aha, :mh_aha],
        )
      rescue HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError => _e
        return { score: -1, mh_score: -1, aha_failed_reason: 'NO_MCI_UNIQUE_ID' }
      end

      raise HmisExternalApis::AcHmis::Aha::Error, 'Response does not contain AHA score' unless result[:aha].present?

      {
        score: result[:aha].score,
        mh_score: result[:mh_aha]&.score || -1,
        mci_quality_indicator: result[:aha].mci_quality_indicator,
        dw_client_id: result[:aha].dw_client_id || client.ac_hmis_mci_unique_id&.value,
        generator: result[:aha].generator,
        aha_failed_reason: nil,
      }
    end
  end
end
