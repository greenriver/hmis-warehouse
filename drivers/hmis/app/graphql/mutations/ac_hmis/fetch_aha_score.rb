###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AcHmis::FetchAhaScore < CleanBaseMutation
    description 'Return AHA score for client'

    argument :client_id, ID, required: true

    field :score, Integer, null: true
    field :alt_aha_flag, Boolean, null: true
    field :dw_client_id, String, null: true
    field :generator, String, null: true

    def resolve(client_id:)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: 'AHA connection is not configured' unless HmisExternalApis::AcHmis::Aha.enabled?
      return { errors: errors } if errors.any?

      # If you have permission to view this client, you can fetch their AHA score
      client = Hmis::Hud::Client.viewable_by(current_user).find_by(id: client_id)
      access_denied! unless client.present?

      aha = HmisExternalApis::AcHmis::Aha.new
      result = aha.fetch_score(client)

      return { score: -1 } if result.nil?

      {
        score: result.score,
        alt_aha_flag: result.alt_aha_flag,
        dw_client_id: result.dw_client_id,
        generator: result.generator,
      }
    end
  end
end
