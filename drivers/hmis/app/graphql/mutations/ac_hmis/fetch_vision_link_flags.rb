###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AcHmis::FetchVisionLinkFlags < CleanBaseMutation
    description 'Return VisionLink eligibility flags for client'

    argument :client_id, ID, required: true

    field :is_eligible_ra, Boolean, null: true
    field :section_8, Boolean, null: true
    field :city_of_pittsburgh, Boolean, null: true
    field :subsidized_housing, Boolean, null: true
    field :recent_eviction_case, Boolean, null: true
    field :dw_client_id, String, null: true
    field :failed_reason, AcHmis::FetchAhaScore::AhaFailedReason, null: true

    def resolve(client_id:)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: 'AHA connection is not configured' unless HmisExternalApis::AcHmis::Aha.enabled?
      return { errors: errors } if errors.any?

      client = Hmis::Hud::Client.viewable_by(current_user).find_by(id: client_id)
      access_denied! unless client.present?

      aha = HmisExternalApis::AcHmis::Aha.new
      begin
        results = aha.fetch_score(client, requested_generators: [:visionlink])
      rescue HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError => _e
        return { failed_reason: 'NO_MCI_UNIQUE_ID' }
      end

      visionlink = results[:visionlink]
      return {} unless visionlink

      {
        is_eligible_ra: visionlink.is_eligible_ra,
        section_8: visionlink.section_8,
        city_of_pittsburgh: visionlink.city_of_pittsburgh,
        subsidized_housing: visionlink.subsidized_housing,
        recent_eviction_case: visionlink.recent_eviction_case,
        dw_client_id: visionlink.dw_client_id || client.ac_hmis_mci_unique_id&.value,
        failed_reason: nil,
      }
    end
  end
end
