###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
        result = aha.fetch_score(client, lookup_catalyst: lookup_catalyst, lookup_reason: lookup_reason)
      rescue HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError => _e
        return { score: -1, aha_failed_reason: 'NO_MCI_UNIQUE_ID' }
      end

      {
        score: result.score,
        mci_quality_indicator: result.mci_quality_indicator,
        dw_client_id: result.dw_client_id,
        generator: result.generator,
        aha_failed_reason: nil,
      }
    end
  end
end
